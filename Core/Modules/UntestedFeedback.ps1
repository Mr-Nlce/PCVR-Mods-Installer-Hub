# Feedback observes test results; it never promotes a candidate or changes VR readiness.
. (Join-Path $PSScriptRoot 'InstallerTestReport.ps1')

function global:Get-UntestedFeedbackReports {
    param($Game)
    if (-not $Game -or -not $Game.Id) { return @() }
    try {
        $folder = Get-PCVRTestReportFolder -NoCreate
        if (-not [IO.Directory]::Exists($folder)) { return @() }
        foreach ($file in @(Get-ChildItem -LiteralPath $folder -Filter '*-test-result*.txt' -File | Sort-Object LastWriteTimeUtc -Descending)) {
            $reader = $null
            try {
                $reader = [IO.StreamReader]::new($file.FullName, [Text.Encoding]::UTF8, $true)
                $id = ''; $outcome = ''
                for ($i=0; $i -lt 12 -and -not $reader.EndOfStream; $i++) {
                    $line = $reader.ReadLine()
                    if ($line.StartsWith('Installer ID: ')) { $id = $line.Substring(14) }
                    if ($line.StartsWith('Installer result: ')) { $outcome = $line.Substring(18) }
                }
                if ($id -eq [string]$Game.Id) { [pscustomobject]@{Path=$file.FullName;Outcome=$outcome} }
            } catch { } finally { if ($reader) { $reader.Dispose() } }
        }
    } catch { }
}

function global:Get-UntestedFeedbackUrl {
    param($Game)
    $url = 'https://github.com/Mr-Nlce/PCVR-Mods-Installer-Hub/issues/new?template=untested-installer-test.yml'
    $url += '&title=' + [Uri]::EscapeDataString('[Test] '+[string]$Game.Title)
    if ($global:HUB_VERSION) { $url += '&hub-version=' + [Uri]::EscapeDataString([string]$global:HUB_VERSION) }
    return $url
}

function global:Open-UntestedFeedbackTarget {
    param([string]$Target, [string]$Arguments='')
    if ($Arguments) { Start-Process -FilePath $Target -ArgumentList $Arguments -ErrorAction Stop | Out-Null }
    else { Start-Process -FilePath $Target -ErrorAction Stop | Out-Null }
}

function global:Invoke-UntestedFeedback {
    param($Game)
    if (-not $Game.UntestedInstaller) { return }
    $failures = @()
    try { Open-UntestedFeedbackTarget -Target (Get-UntestedFeedbackUrl $Game) }
    catch { $failures += 'The GitHub form could not be opened: '+$_.Exception.Message }
    try {
        $folder = Get-PCVRTestReportFolder
        $report = @(Get-UntestedFeedbackReports $Game) | Select-Object -First 1
        $arguments = if ($report) { '/select,"'+$report.Path+'"' } else { '"'+$folder+'"' }
        Open-UntestedFeedbackTarget -Target 'explorer.exe' -Arguments $arguments
    } catch { $failures += 'The report folder could not be opened: '+$_.Exception.Message }
    if ($failures.Count) { [void][Windows.MessageBox]::Show(($failures -join "`n`n"),'Provide feedback') }
}

function global:New-UntestedFeedbackButton {
    param($Game)
    if (-not $Game.UntestedInstaller) { return $null }
    $button = [Windows.Controls.Button]::new()
    $button.Content = 'Provide feedback '+[char]0x2665
    $button.FontFamily = [Windows.Media.FontFamily]::new('Segoe UI')
    $button.FontSize = 11; $button.Padding = [Windows.Thickness]::new(8,3,8,3)
    $button.Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#e0192420')
    $button.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#8cddb0')
    $button.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString('#4b7960')
    $button.Cursor = [Windows.Input.Cursors]::Hand
    $button.ToolTip = 'Open the GitHub form and Core\Logs\Untested. Drag the matching TXT into Installer log. Review it before sharing; nothing is uploaded automatically.'
    $button.Resources['feedbackGame'] = $Game
    $button.Add_Click({ Invoke-UntestedFeedback -Game $this.Resources['feedbackGame'] })
    return $button
}

function global:Update-UntestedFeedbackReminder {
    param($Card, $Game, $State)
    if (-not $Card -or -not $Card.Resources.Contains('feedbackReminder')) { return }
    $show = [bool]$Game.UntestedInstaller
    if ($show) { $show = -not [bool](Get-HubSetting -Key ('untestedFeedbackHidden.'+$Game.Id) -Default $false) }
    if ($show) {
        if ($State) { $show = [string]$State.State -in @('ready','update') }
        else { $report = @(Get-UntestedFeedbackReports $Game) | Select-Object -First 1; $show = $report -and $report.Outcome -eq 'SUCCESS' }
    }
    $Card.Resources['feedbackReminder'].Visibility = if ($show) { 'Visible' } else { 'Collapsed' }
    if (-not $show) { $Card.Resources['feedbackShowTimer'].Stop(); $Card.Resources['feedbackClose'].Visibility='Collapsed' }
}

function global:Initialize-UntestedFeedbackCard {
    param($Card, $Game)
    if (-not $Game.UntestedInstaller -or $Card.Resources.Contains('feedbackReminder')) { return }
    # Keep the actual card, embedded game identity, scan resources and S/M/L transform intact.
    # The adorner occupies reserved space above it and never intercepts the card's actions.
    if (-not ('PCVR.UntestedFeedbackAdorner' -as [type])) {
        Add-Type -WarningAction SilentlyContinue -ReferencedAssemblies @('PresentationFramework','PresentationCore','WindowsBase','System.Xaml') -TypeDefinition @'
using System.Windows;
using System.Windows.Documents;
using System.Windows.Media;
namespace PCVR {
 public sealed class UntestedFeedbackAdorner : Adorner {
  readonly UIElement child;
  public UntestedFeedbackAdorner(UIElement card, UIElement content):base(card){child=content;AddVisualChild(child);}
  protected override int VisualChildrenCount {get{return 1;}}
  protected override Visual GetVisualChild(int index){return child;}
  protected override Size MeasureOverride(Size size){child.Measure(new Size(AdornedElement.RenderSize.Width,28));return AdornedElement.RenderSize;}
  protected override Size ArrangeOverride(Size size){child.Arrange(new Rect(0,-30,AdornedElement.RenderSize.Width,26));return size;}
  protected override HitTestResult HitTestCore(PointHitTestParameters hit){return null;}
 }
}
'@
    }
    $margin=$Card.Margin
    $Card.Margin=[Windows.Thickness]::new($margin.Left,32,$margin.Right,$margin.Bottom)
    $row=[Windows.Controls.StackPanel]::new();$row.Orientation='Horizontal';$row.Visibility='Collapsed'
    $row.Resources['feedbackCard']=$Card
    $feedback=New-UntestedFeedbackButton $Game
    [void]$row.Children.Add($feedback)
    $close=[Windows.Controls.Button]::new();$close.Content=[char]0x00d7;$close.FontSize=13
    $close.Width=22;$close.Margin=[Windows.Thickness]::new(3,0,0,0)
    $close.ToolTip='Hide this reminder. Provide feedback remains on the game detail page.'
    $close.Visibility='Collapsed';$close.Resources['feedbackCard']=$Card
    [void]$row.Children.Add($close)
    $timer=[Windows.Threading.DispatcherTimer]::new();$timer.Interval=[TimeSpan]::FromSeconds(3);$timer.Tag=$Card
    $timer.Add_Tick({$this.Stop();$this.Tag.Resources['feedbackClose'].Visibility='Visible'})
    $row.Add_MouseEnter({$c=$this.Resources['feedbackCard'];$c.Resources['feedbackShowTimer'].Start()})
    $row.Add_MouseLeave({$c=$this.Resources['feedbackCard'];$c.Resources['feedbackShowTimer'].Stop();$c.Resources['feedbackClose'].Visibility='Collapsed'})
    $close.Add_Click({
        $c=$this.Resources['feedbackCard'];$g=$c.Resources['gameData']
        Set-HubSetting -Key ('untestedFeedbackHidden.'+$g.Id) -Value $true
        Update-UntestedFeedbackReminder -Card $c -Game $g
    })
    $Card.Resources['feedbackReminder']=$row;$Card.Resources['feedbackClose']=$close;$Card.Resources['feedbackShowTimer']=$timer
    $Card.Add_Loaded({
        $layer=[Windows.Documents.AdornerLayer]::GetAdornerLayer($this)
        if($layer -and -not $this.Resources.Contains('feedbackLayer')){
            $ad=$this.Resources['feedbackAdorner']
            if(-not $ad){
                $ad=[PCVR.UntestedFeedbackAdorner]::new($this,$this.Resources['feedbackReminder'])
                $visibility=[Windows.Data.Binding]::new('IsVisible');$visibility.Source=$this
                $visibility.Converter=[Windows.Controls.BooleanToVisibilityConverter]::new()
                [void]$ad.SetBinding([Windows.UIElement]::VisibilityProperty,$visibility)
            }
            $layer.Add($ad);$this.Resources['feedbackAdorner']=$ad;$this.Resources['feedbackLayer']=$layer
        }
        $g=$this.Resources['gameData'];$st=$null
        if($global:gameStateMap){$st=$global:gameStateMap[$g.Title]}
        Update-UntestedFeedbackReminder -Card $this -Game $g -State $st
    })
    $Card.Add_Unloaded({
        $this.Resources['feedbackShowTimer'].Stop()
        if($this.Resources.Contains('feedbackAdorner')){
            $this.Resources['feedbackLayer'].Remove($this.Resources['feedbackAdorner'])
            $this.Resources.Remove('feedbackLayer')
        }
    })
}
