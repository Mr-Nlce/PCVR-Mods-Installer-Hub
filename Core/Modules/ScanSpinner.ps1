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
    # The shipped launcher uses Windows PowerShell 5.1. Its .NET Framework WPF
    # compiler supports the dedicated render thread below. PowerShell 7's
    # runtime compiler cannot combine the .NET 10 WPF implementation assemblies
    # with System.Private.CoreLib in one Add-Type compilation; attempting it
    # only produced a caught TerminatingError. On that non-shipping host the
    # scan remains fully functional and simply omits the decorative spinner.
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
      if (-not ([System.Management.Automation.PSTypeName]'PcvrScanSpinner').Type) {
        # Use exact loaded assembly paths rather than short GAC names. This
        # prevents a normal Windows PowerShell launch from logging a false
        # missing-reference error before the window opens.
        $spinnerReferences = @(
            [System.Windows.Application].Assembly.Location,
            [System.Windows.Media.Visual].Assembly.Location,
            [System.Windows.Threading.Dispatcher].Assembly.Location,
            [System.Windows.Markup.XamlReader].Assembly.Location
        )
        # .NET Framework's FrameworkElement surface exposes IQueryAmbient from
        # System.Xaml; include its exact loaded GAC path as well.
        Add-Type -AssemblyName System.Xaml -ErrorAction Stop
        $spinnerReferences += [System.Xaml.XamlReader].Assembly.Location
        $spinnerReferences = @($spinnerReferences | Where-Object { $_ } | Select-Object -Unique)
        Add-Type -ReferencedAssemblies $spinnerReferences -TypeDefinition @'
using System;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Shapes;
using System.Windows.Threading;
using System.Windows.Interop;
using System.Runtime.InteropServices;

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

// The library switch shares the scan spinner's independent WPF render host.
// A DispatcherTimer on this STA thread fills the four glyph squares in order
// even while PowerShell is synchronously building the next view.
public class PcvrViewSwitchIndicator
{
    private HostVisual _host;
    private Thread _thread;
    private Dispatcher _dispatcher;
    private VisualTarget _target;
    private PcvrVisualHost _element;
    private DispatcherTimer _timer;
    private DispatcherTimer _revealTimer;
    private DispatcherTimer _watchdog;
    private Rectangle[] _squares;
    private Rectangle[] _popupSquares;
    private Window _popup;
    private volatile int _phase;
    private volatile bool _ready;
    private volatile bool _popupVisible;

    public FrameworkElement Element { get { return _element; } }
    public int Phase { get { return _phase; } }
    public bool Ready { get { return _ready; } }
    public bool PopupVisible { get { return _popupVisible; } }


    [DllImport("user32.dll", EntryPoint="GetWindowLongW")]
    private static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll", EntryPoint="SetWindowLongW")]
    private static extern int SetWindowLong(IntPtr hwnd, int index, int value);

    public static PcvrViewSwitchIndicator Create(double left, double top)
    {
        return CreateDelayed(left, top, 0);
    }

    public static PcvrViewSwitchIndicator CreateDelayed(double left, double top, int delayMs)
    {
        PcvrViewSwitchIndicator s = new PcvrViewSwitchIndicator();
        s._host = new HostVisual();
        s._element = new PcvrVisualHost(s._host);
        ManualResetEvent ready = new ManualResetEvent(false);
        s._thread = new Thread(delegate()
        {
            try
            {
                s._dispatcher = Dispatcher.CurrentDispatcher;
                s._target = new VisualTarget(s._host);
                s._target.RootVisual = s.Build();
                s._popup = new Window();
                s._popup.WindowStyle = WindowStyle.None;
                s._popup.ResizeMode = ResizeMode.NoResize;
                s._popup.AllowsTransparency = true;
                s._popup.Background = Brushes.Transparent;
                s._popup.ShowInTaskbar = false;
                s._popup.ShowActivated = false;
                s._popup.Topmost = true;
                s._popup.Width = 14;
                s._popup.Height = 14;
                s._popup.Left = left;
                s._popup.Top = top;
                s._popup.Content = s.BuildPopup();
                s._popup.SourceInitialized += delegate {
                    IntPtr hwnd = new WindowInteropHelper(s._popup).Handle;
                    const int GWL_EXSTYLE = -20;
                    const int WS_EX_TRANSPARENT = 0x20;
                    const int WS_EX_TOOLWINDOW = 0x80;
                    const int WS_EX_NOACTIVATE = 0x08000000;
                    SetWindowLong(hwnd, GWL_EXSTYLE, GetWindowLong(hwnd, GWL_EXSTYLE) |
                        WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
                };
                if (delayMs <= 0)
                {
                    s._popup.Show();
                    s._popupVisible = s._popup.IsVisible;
                }
                else
                {
                    s._revealTimer = new DispatcherTimer(DispatcherPriority.Render, s._dispatcher);
                    s._revealTimer.Interval = TimeSpan.FromMilliseconds(delayMs);
                    s._revealTimer.Tick += delegate {
                        s._revealTimer.Stop();
                        s._popup.Show();
                        s._popupVisible = s._popup.IsVisible;
                    };
                    s._revealTimer.Start();
                }
                s.Paint(1);
                s._timer = new DispatcherTimer(DispatcherPriority.Render, s._dispatcher);
                s._timer.Interval = TimeSpan.FromMilliseconds(300);
                s._timer.Tick += delegate { s.Paint(s._phase >= 4 ? 1 : s._phase + 1); };
                s._timer.Start();
                s._watchdog = new DispatcherTimer(DispatcherPriority.Background, s._dispatcher);
                s._watchdog.Interval = delayMs > 0 ? TimeSpan.FromSeconds(90) : TimeSpan.FromSeconds(15);
                s._watchdog.Tick += delegate {
                    s._watchdog.Stop();
                    s._timer.Stop();
                    try { s._popup.Close(); } catch { }
                    s._popupVisible = false;
                    s._dispatcher.BeginInvokeShutdown(DispatcherPriority.Background);
                };
                s._watchdog.Start();
                s._ready = true;
            }
            catch { }
            finally { ready.Set(); }
            if (s._ready) { try { Dispatcher.Run(); } catch { } }
        });
        s._thread.SetApartmentState(ApartmentState.STA);
        s._thread.IsBackground = true;
        s._thread.Start();
        ready.WaitOne(400);
        return s;
    }

    private Visual Build()
    {
        Canvas root = new Canvas();
        root.Width = 14;
        root.Height = 14;
        _squares = new Rectangle[4];
        for (int i = 0; i < 4; i++)
        {
            Rectangle square = new Rectangle();
            square.Width = 5.5;
            square.Height = 5.5;
            square.RadiusX = 1;
            square.RadiusY = 1;
            Canvas.SetLeft(square, (i % 2) * 8.5);
            Canvas.SetTop(square, (i / 2) * 8.5);
            root.Children.Add(square);
            _squares[i] = square;
        }
        root.Measure(new Size(14, 14));
        root.Arrange(new Rect(0, 0, 14, 14));
        return root;
    }

    private Visual BuildPopup()
    {
        Canvas root = new Canvas();
        root.Width = 14;
        root.Height = 14;
        _popupSquares = new Rectangle[4];
        for (int i = 0; i < 4; i++)
        {
            Rectangle square = new Rectangle();
            square.Width = 5.5;
            square.Height = 5.5;
            square.RadiusX = 1;
            square.RadiusY = 1;
            Canvas.SetLeft(square, (i % 2) * 8.5);
            Canvas.SetTop(square, (i / 2) * 8.5);
            root.Children.Add(square);
            _popupSquares[i] = square;
        }
        return root;
    }

    private void Paint(int phase)
    {
        string[] colors = { "#6BF49B", "#3A8ADD", "#3A8ADD", "#6BF49B" };
        for (int i = 0; i < 4; i++)
        {
            Brush fill = (Brush)new BrushConverter().ConvertFromString(i < phase ? colors[i] : "#AAAAAA");
            _squares[i].Fill = fill;
            _popupSquares[i].Fill = fill;
        }
        _phase = phase;
    }

    public void Stop()
    {
        try { if (_revealTimer != null && _dispatcher != null) { _dispatcher.Invoke(new Action(delegate { _revealTimer.Stop(); })); } } catch { }
        try { if (_popup != null && _dispatcher != null) { _dispatcher.Invoke(new Action(delegate { _popup.Close(); _popupVisible = false; })); } } catch { }
        try { if (_dispatcher != null) { _dispatcher.InvokeShutdown(); } } catch { }
        try { if (_thread != null && _thread.IsAlive) { _thread.Join(500); } } catch { }
        _dispatcher = null;
        _thread = null;
        _target = null;
    }
}

// A full-row version of the Scan button light for menu actions. Its own STA
// dispatcher keeps the border moving even while the Hub rebuilds on its UI
// thread. The transparent popup does not intercept menu clicks.
public class PcvrMenuActionGlow
{
    private double _width;
    private double _height;
    private double _left;
    private double _top;
    private Thread _thread;
    private Dispatcher _dispatcher;
    private DispatcherTimer _revealTimer;
    private Window _popup;
    private Path _brightPath;
    private volatile bool _ready;
    private volatile bool _popupVisible;

    public bool Ready { get { return _ready; } }
    public bool PopupVisible { get { return _popupVisible; } }
    public double PopupWidth { get { return _width; } }
    public double PopupHeight { get { return _height; } }
    public double PopupLeft { get { return _left; } }
    public double PopupTop { get { return _top; } }
    public double GlowOffset {
        get {
            if (_dispatcher == null || _brightPath == null) return 0;
            try { return (double)_dispatcher.Invoke(new Func<double>(delegate { return _brightPath.StrokeDashOffset; })); }
            catch { return 0; }
        }
    }

    [DllImport("user32.dll", EntryPoint="GetWindowLongW")]
    private static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll", EntryPoint="SetWindowLongW")]
    private static extern int SetWindowLong(IntPtr hwnd, int index, int value);

    public static PcvrMenuActionGlow CreateDelayed(double left, double top,
                                                    double width, double height, int delayMs)
    {
        PcvrMenuActionGlow s = new PcvrMenuActionGlow();
        s._width = Math.Max(24, width);
        s._height = Math.Max(20, height);
        s._left = left;
        s._top = top;
        ManualResetEvent ready = new ManualResetEvent(false);
        s._thread = new Thread(delegate()
        {
            try
            {
                s._dispatcher = Dispatcher.CurrentDispatcher;
                s._popup = new Window();
                s._popup.WindowStyle = WindowStyle.None;
                s._popup.ResizeMode = ResizeMode.NoResize;
                s._popup.AllowsTransparency = true;
                s._popup.Background = Brushes.Transparent;
                s._popup.ShowInTaskbar = false;
                s._popup.ShowActivated = false;
                s._popup.Topmost = true;
                s._popup.Width = s._width;
                s._popup.Height = s._height;
                s._popup.Left = left;
                s._popup.Top = top;
                s._popup.Content = s.Build(s._popup.Width, s._popup.Height);
                s._popup.SourceInitialized += delegate {
                    IntPtr hwnd = new WindowInteropHelper(s._popup).Handle;
                    const int GWL_EXSTYLE = -20;
                    const int WS_EX_TRANSPARENT = 0x20;
                    const int WS_EX_TOOLWINDOW = 0x80;
                    const int WS_EX_NOACTIVATE = 0x08000000;
                    SetWindowLong(hwnd, GWL_EXSTYLE, GetWindowLong(hwnd, GWL_EXSTYLE) |
                        WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
                };
                s._revealTimer = new DispatcherTimer(DispatcherPriority.Render, s._dispatcher);
                s._revealTimer.Interval = TimeSpan.FromMilliseconds(delayMs);
                s._revealTimer.Tick += delegate {
                    s._revealTimer.Stop();
                    try { s._popup.Show(); s._popupVisible = s._popup.IsVisible; } catch { }
                };
                s._revealTimer.Start();
                s._ready = true;
            }
            catch { }
            finally { ready.Set(); }
            if (s._ready) { try { Dispatcher.Run(); } catch { } }
        });
        s._thread.SetApartmentState(ApartmentState.STA);
        s._thread.IsBackground = true;
        s._thread.Start();
        ready.WaitOne(400);
        return s;
    }

    private Path Stroke(Rect rect, double thickness, double opacity, double segment,
                        double halfPerimeter, double seconds, Effect effect)
    {
        Path p = new Path();
        p.Data = new RectangleGeometry(rect, 7, 7);
        SolidColorBrush brush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#6BF49B"));
        brush.Opacity = opacity;
        p.Stroke = brush;
        p.StrokeThickness = thickness;
        p.StrokeStartLineCap = PenLineCap.Round;
        p.StrokeEndLineCap = PenLineCap.Round;
        p.StrokeDashCap = PenLineCap.Round;
        p.Effect = effect;
        if (segment > 0)
        {
            p.StrokeDashArray = new DoubleCollection { segment / thickness,
                Math.Max(0.01, (halfPerimeter - segment) / thickness) };
            DoubleAnimation move = new DoubleAnimation();
            move.From = 0;
            move.To = -(halfPerimeter / thickness);
            move.Duration = new Duration(TimeSpan.FromSeconds(seconds));
            move.RepeatBehavior = RepeatBehavior.Forever;
            p.BeginAnimation(Shape.StrokeDashOffsetProperty, move);
        }
        return p;
    }

    private Canvas Build(double width, double height)
    {
        Canvas root = new Canvas();
        root.Width = width;
        root.Height = height;
        Rect rect = new Rect(2, 2, Math.Max(1, width - 4), Math.Max(1, height - 4));
        double halfPerimeter = (2 * (rect.Width + rect.Height) - 56 + 14 * Math.PI) / 2;
        double segment = halfPerimeter * 0.30;
        root.Children.Add(Stroke(rect, 1.3, 0.48, 0, halfPerimeter, 0, null));
        root.Children.Add(Stroke(rect, 5.4, 0.50, segment, halfPerimeter, 2.2,
            new BlurEffect { Radius = 8, KernelType = KernelType.Gaussian }));
        _brightPath = Stroke(rect, 2.0, 0.98, segment, halfPerimeter, 2.2,
            new BlurEffect { Radius = 1.5, KernelType = KernelType.Gaussian });
        root.Children.Add(_brightPath);
        return root;
    }

    public void Stop()
    {
        try {
            if (_dispatcher != null) _dispatcher.Invoke(new Action(delegate {
                if (_revealTimer != null) _revealTimer.Stop();
                if (_popup != null) { _popup.Close(); _popupVisible = false; }
            }));
        } catch { }
        try { if (_dispatcher != null) _dispatcher.InvokeShutdown(); } catch { }
        try { if (_thread != null && _thread.IsAlive) _thread.Join(500); } catch { }
        _dispatcher = null;
        _thread = null;
    }
}
'@
      }
      $global:ScanSpinnerReady = $true
    }
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

$global:ViewSwitchIndicatorActive = $null

function global:Start-ViewSwitchIndicator {
    if (-not $global:ScanSpinnerReady) { return $null }
    # Each click owns its own host. A late finally from an earlier click may
    # only remove that earlier host, never the newer switch's animation.
    Stop-ViewSwitchIndicator -Immediate
    try {
        $hostGrid = $window.FindName('DiscoverGlyphHost')
        if (-not $hostGrid) { return $null }
        $screenPoint = $hostGrid.PointToScreen([System.Windows.Point]::new(0, 0))
        $source = [System.Windows.PresentationSource]::FromVisual($hostGrid)
        if ($source -and $source.CompositionTarget) { $screenPoint = $source.CompositionTarget.TransformFromDevice.Transform($screenPoint) }
        $indicator = [PcvrViewSwitchIndicator]::Create($screenPoint.X, $screenPoint.Y)
        if (-not $indicator -or -not $indicator.Ready) {
            if ($indicator) { $indicator.Stop() }
            return $null
        }
        $element = $indicator.Element
        $element.Width = 14
        $element.Height = 14
        $element.IsHitTestVisible = $false
        [System.Windows.Controls.Grid]::SetRowSpan($element, 3)
        [System.Windows.Controls.Grid]::SetColumnSpan($element, 3)
        [void]$hostGrid.Children.Add($element)
        $token = [Guid]::NewGuid().ToString('N')
        $global:ViewSwitchIndicatorActive = @{ Token = $token; Indicator = $indicator; Element = $element; Host = $hostGrid; StartedAtUtc = [DateTime]::UtcNow; StopTimer = $null }
        # Commit the hosted visual before synchronous tile/status work begins.
        $hostGrid.UpdateLayout()
        foreach ($priority in @('Render', 'Background')) {
            $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::$priority)
        }
        return $token
    } catch {
        Stop-ViewSwitchIndicator -Immediate
        return $null
    }
}

function global:Stop-ViewSwitchIndicator {
    param([string]$Token, [switch]$Immediate)
    $active = $global:ViewSwitchIndicatorActive
    if (-not $active -or ($Token -and $Token -cne $active.Token)) { return }
    if (-not $Immediate) {
        # Four 300 ms steps must remain visible even when cached views switch
        # immediately. The UI dispatcher owns the one-shot cleanup timer.
        $remainingMs = 1150 - ([DateTime]::UtcNow - $active.StartedAtUtc).TotalMilliseconds
        if ($remainingMs -gt 0 -and -not $active.StopTimer) {
            try {
                $timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background, $window.Dispatcher)
                $timer.Interval = [TimeSpan]::FromMilliseconds($remainingMs)
                $timerToken = $active.Token
                $timer.Add_Tick({
                    $timer.Stop()
                    Stop-ViewSwitchIndicator -Token $timerToken -Immediate
                }.GetNewClosure())
                $active.StopTimer = $timer
                $timer.Start()
                return
            } catch { }
        } elseif ($active.StopTimer) { return }
    }
    $global:ViewSwitchIndicatorActive = $null
    try { if ($active.StopTimer) { $active.StopTimer.Stop() } } catch { }
    try { [void]$active.Host.Children.Remove($active.Element) } catch { }
    try { $active.Indicator.Stop() } catch { }
}

# A full-row Scan-style glow for slow menu work. It appears after half a second,
# and its render thread keeps it moving while the Hub dispatcher is blocked.
$global:HubActionIndicatorActive = $null
function global:Start-HubActionIndicator {
    param([System.Windows.FrameworkElement]$Target,[int]$DelayMilliseconds=500,
        [double]$BottomExtension=0,[double]$RightInset=0,[switch]$FitTargetEdges)
    if (-not $global:ScanSpinnerReady -or -not $Target -or -not $Target.IsVisible) { return $null }
    Stop-HubActionIndicator
    try {
        $targetWidth = [double]$Target.ActualWidth
        $targetHeight = [double]$Target.ActualHeight
        if ($targetWidth -lt 24 -or $targetHeight -lt 20) { return $null }
        # Card sizes use LayoutTransform. ActualWidth/ActualHeight remain in
        # unscaled card coordinates, but PointToScreen is scaled. Measure the
        # screen-space corners of the actual clickable button.
        $point = $Target.PointToScreen([System.Windows.Point]::new(0, 0))
        $farPoint = $Target.PointToScreen([System.Windows.Point]::new(
            [Math]::Max(0, $targetWidth - [Math]::Max(0, $RightInset)), $targetHeight))
        $source = [System.Windows.PresentationSource]::FromVisual($Target)
        if ($source -and $source.CompositionTarget) {
            $point = $source.CompositionTarget.TransformFromDevice.Transform($point)
            $farPoint = $source.CompositionTarget.TransformFromDevice.Transform($farPoint)
        }
        $width = [double]($farPoint.X - $point.X)
        $indicatorHeight = [double]($farPoint.Y - $point.Y) + [Math]::Max(0, $BottomExtension)
        if ($width -lt 24 -or $indicatorHeight -lt 20) { return $null }
        if ($FitTargetEdges) {
            # The glow path is inset 2px within its transparent popup. Place
            # that path on all four real button edges, not inside the button.
            $point = [System.Windows.Point]::new($point.X - 2, $point.Y - 2)
            $width += 4
            $indicatorHeight += 4
        }
        $indicator = [PcvrMenuActionGlow]::CreateDelayed($point.X, $point.Y, $width, $indicatorHeight, ([Math]::Max(0,$DelayMilliseconds)))
        if (-not $indicator -or -not $indicator.Ready) {
            if ($indicator) { $indicator.Stop() }
            return $null
        }
        $token = [Guid]::NewGuid().ToString('N')
        $global:HubActionIndicatorActive = @{ Token = $token; Indicator = $indicator }
        return $token
    } catch {
        Stop-HubActionIndicator
        return $null
    }
}

function global:Stop-HubActionIndicator {
    param([string]$Token)
    $active = $global:HubActionIndicatorActive
    if (-not $active -or ($Token -and $Token -cne $active.Token)) { return }
    $global:HubActionIndicatorActive = $null
    try { $active.Indicator.Stop() } catch { }
}
