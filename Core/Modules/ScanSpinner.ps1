# -------------------------------------------------------
# Scan spinner - the neon light that runs around the
# "Scan games" button while a scan is in progress.
#
# The whole point is to keep moving while the scan has the UI thread
# pinned. A normal WPF animation is driven by that same thread and stops
# dead with it, and a PowerShell background thread would need this
# runspace - which the scan is already holding. So the moving part lives
# in C#, on its own STA thread with its own Dispatcher, composited into
# the window through a HostVisual and drawn by WPF's render thread.
#
# The light is a rounded-rect Path whose StrokeDashArray leaves exactly
# two lit segments, with StrokeDashOffset animated so they travel round.
# It is drawn twice, both passes blurred: a broad faint halo underneath
# and a softened band on top - a moving glow, not a hard little stick.
# -------------------------------------------------------

$global:ScanSpinnerReady = $false
try {
    if (-not ([System.Management.Automation.PSTypeName]'PcvrScanSpinner').Type) {
        Add-Type -ReferencedAssemblies @("PresentationCore","PresentationFramework","WindowsBase","System.Xaml") -TypeDefinition @'
using System;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Shapes;
using System.Windows.Threading;

public class PcvrVisualHost : FrameworkElement
{
    private readonly HostVisual _host;
    public PcvrVisualHost(HostVisual host)
    {
        _host = host;
        IsHitTestVisible = false;
        AddVisualChild(host);
    }
    protected override int VisualChildrenCount { get { return 1; } }
    protected override Visual GetVisualChild(int index) { return _host; }
}

public class PcvrScanSpinner
{
    private HostVisual _host;
    private Thread _thread;
    private Dispatcher _dispatcher;
    private PcvrVisualHost _element;
    private VisualTarget _target;

    private double _radius;
    private string _color;
    private double _seconds;
    private double _thickness;

    public FrameworkElement Element { get { return _element; } }

    public static PcvrScanSpinner Create(double width, double height, double radius,
                                         string colorHex, double seconds, double thickness)
    {
        PcvrScanSpinner s = new PcvrScanSpinner();
        s._host = new HostVisual();
        s._element = new PcvrVisualHost(s._host);
        s._radius = radius;
        s._color = colorHex;
        s._seconds = seconds;
        s._thickness = thickness;

        ManualResetEvent ready = new ManualResetEvent(false);
        s._thread = new Thread(delegate()
        {
            try
            {
                s._dispatcher = Dispatcher.CurrentDispatcher;
                s._target = new VisualTarget(s._host);
                s._target.RootVisual = s.Build(width, height);
            }
            catch { }
            ready.Set();
            try { Dispatcher.Run(); } catch { }
        });
        s._thread.SetApartmentState(ApartmentState.STA);
        s._thread.IsBackground = true;
        s._thread.Start();
        // Short wait only - just long enough for the visual to exist. Never
        // long enough for the user to feel it as a stall.
        ready.WaitOne(400);
        return s;
    }

    // The button changes width when its label switches and again when the
    // result count appears, so the light has to be redrawn at the new size
    // or it ends up running through the middle of the button.
    public void Resize(double width, double height)
    {
        Dispatcher d = _dispatcher;
        if (d == null) { return; }
        double w = width, h = height;
        try
        {
            d.BeginInvoke(DispatcherPriority.Normal, new Action(delegate()
            {
                try { if (_target != null) { _target.RootVisual = Build(w, h); } } catch { }
            }));
        }
        catch { }
    }

    private Path MakeStroke(Rect r, double rad, Color c, double thickness,
                            double opacity, double lit, double unit, Effect fx)
    {
        Path p = new Path();
        p.Data = new RectangleGeometry(r, rad, rad);
        SolidColorBrush b = new SolidColorBrush(c);
        b.Opacity = opacity;
        p.Stroke = b;
        p.StrokeThickness = thickness;
        p.StrokeStartLineCap = PenLineCap.Round;
        p.StrokeEndLineCap = PenLineCap.Round;
        p.StrokeDashCap = PenLineCap.Round;
        p.Fill = null;
        p.Effect = fx;

        // StrokeDashArray is measured in multiples of the stroke thickness,
        // so the same visual length needs different numbers per layer.
        DoubleCollection dashes = new DoubleCollection();
        dashes.Add(lit / thickness);
        dashes.Add(Math.Max(0.01, (unit - lit) / thickness));
        p.StrokeDashArray = dashes;
        p.StrokeDashOffset = 0;

        DoubleAnimation a = new DoubleAnimation();
        a.From = 0;
        a.To = -(unit / thickness);
        a.Duration = new Duration(TimeSpan.FromSeconds(_seconds));
        a.RepeatBehavior = RepeatBehavior.Forever;
        p.BeginAnimation(Shape.StrokeDashOffsetProperty, a);
        return p;
    }

    private Visual Build(double width, double height)
    {
        Color c = (Color)ColorConverter.ConvertFromString(_color);

        double core = _thickness;
        double half = core / 2.0;
        Rect r = new Rect(half, half, Math.Max(1, width - core), Math.Max(1, height - core));
        double rad = Math.Max(0, Math.Min(_radius, Math.Min(r.Width, r.Height) / 2.0));

        // Two lit segments means the dash pattern repeats exactly twice
        // around the outline, so its length is half the perimeter.
        double perimeter = 2 * (r.Width + r.Height) - 8 * rad + 2 * Math.PI * rad;
        double unit = perimeter / 2.0;
        // Wide arcs, matching the "soft" mockup - a glow travelling the
        // border rather than a short bright stick.
        double lit = unit * 0.30;

        // Both passes are blurred: a broad faint halo underneath and a
        // gently softened band on top. No crisp core and no drop shadow -
        // that combination read as two hard little light sticks.
        BlurEffect halo = new BlurEffect();
        halo.Radius = 9;
        halo.KernelType = KernelType.Gaussian;

        BlurEffect band = new BlurEffect();
        band.Radius = 2.0;
        band.KernelType = KernelType.Gaussian;

        Canvas root = new Canvas();
        root.Width = width;
        root.Height = height;
        root.Background = null;
        root.Children.Add(MakeStroke(r, rad, c, core * 3.2, 0.40, lit, unit, halo));
        root.Children.Add(MakeStroke(r, rad, c, core, 0.95, lit, unit, band));

        root.Measure(new Size(width, height));
        root.Arrange(new Rect(0, 0, width, height));
        return root;
    }

    public void Stop()
    {
        try { if (_dispatcher != null) { _dispatcher.InvokeShutdown(); } } catch { }
        try { if (_thread != null && _thread.IsAlive) { _thread.Join(500); } } catch { }
        _dispatcher = null;
        _thread = null;
        _target = null;
    }
}
'@
    }
    $global:ScanSpinnerReady = $true
} catch {
    $global:ScanSpinnerReady = $false
}

$global:ScanSpinnerActive = $null
$global:ScanSpinnerSizeHooked = $false

# Shows the light on the Scan games button. Never throws: if anything about
# the hosted visual fails, the Hub simply scans without the indicator.
function global:Start-ScanSpinner {
    if (-not $global:ScanSpinnerReady) { return }
    # Already lit? Keep it. The click handler starts the light BEFORE the
    # scan is even scheduled, and the scan function calls in here again -
    # tearing the running light down just to rebuild it would make it
    # blink out at the exact moment it matters most. The SizeChanged hook
    # keeps a reused light matched to the button.
    if ($global:ScanSpinnerActive) { return }
    try {
        $hostGrid = $null
        try { $hostGrid = $window.FindName("CheckInstalledHost") } catch {}
        if (-not $hostGrid) { return }

        $w = [double]$hostGrid.ActualWidth
        $h = [double]$hostGrid.ActualHeight
        if ($w -lt 8 -or $h -lt 8) { return }

        $spin = [PcvrScanSpinner]::Create($w, $h, 6.0, "#6BF49B", 2.2, 2.0)
        if (-not $spin -or -not $spin.Element) { return }

        $el = $spin.Element
        $el.Width = $w
        $el.Height = $h
        $el.HorizontalAlignment = "Center"
        $el.VerticalAlignment = "Center"
        $el.IsHitTestVisible = $false
        [void]$hostGrid.Children.Add($el)

        $global:ScanSpinnerActive = @{ Spinner = $spin; Element = $el; Host = $hostGrid }

        # The button resizes mid-scan (label swap, then the result count),
        # so keep the light matched to it. Registered once for the lifetime
        # of the window; it does nothing while no scan is running.
        if (-not $global:ScanSpinnerSizeHooked) {
            $global:ScanSpinnerSizeHooked = $true
            try {
                $hostGrid.Add_SizeChanged({
                    $a = $global:ScanSpinnerActive
                    if (-not $a) { return }
                    try {
                        $nw = [double]$a.Host.ActualWidth
                        $nh = [double]$a.Host.ActualHeight
                        if ($nw -lt 8 -or $nh -lt 8) { return }
                        $a.Element.Width = $nw
                        $a.Element.Height = $nh
                        $a.Spinner.Resize($nw, $nh)
                    } catch {}
                })
            } catch {}
        }

        # Force the new child through layout and a render pass before the
        # caller goes off and blocks this thread - otherwise the light only
        # reaches the screen once the scan is already over.
        try { $hostGrid.UpdateLayout() } catch {}
        foreach ($prio in @("Render", "Background")) {
            try { $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::$prio) } catch {}
        }
    } catch {
        $global:ScanSpinnerActive = $null
    }
}

# Takes the light away and shuts its thread down. Safe to call when
# nothing is running.
function global:Stop-ScanSpinner {
    $s = $global:ScanSpinnerActive
    if (-not $s) { return }
    $global:ScanSpinnerActive = $null
    try { if ($s.Host -and $s.Element) { $s.Host.Children.Remove($s.Element) } } catch {}
    try { if ($s.Spinner) { $s.Spinner.Stop() } } catch {}
}
