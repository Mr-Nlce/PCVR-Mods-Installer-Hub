# The candidate section owns its collapse state, session dismissal and dwell
# timers. Keeping these on the section also isolates disposable WPF fixtures.
. (Join-Path $PSScriptRoot 'UntestedFeedback.ps1')

function global:Set-UntestedInstallerCollapsed {
    param($Section,[bool]$Collapsed,[switch]$Persist)
    $Section.Resources['untestedCollapsed']=$Collapsed
    $Section.FindName('UntestedGameList').Visibility=if($Collapsed){'Collapsed'}else{'Visible'}
    $Section.FindName('UntestedInstallerSafetyStripe').Visibility=if($Collapsed){'Collapsed'}else{'Visible'}
    $Section.FindName('UntestedInstallerTitle').Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString($(if($Collapsed){'#92929c'}else{'#f3c741'}))
    if($Persist){Set-HubSetting -Key 'untestedInstallersCollapsed' -Value $Collapsed}
}

function global:Update-UntestedInstallerSectionVisibility {
    param($Window,[string]$Query='')
    $section=$Window.FindName('UntestedInstallerSection')
    if(-not $section){return}
    $hidden=[bool]$section.Resources['untestedSessionHidden'] -or [bool](Get-HubSetting -Key 'untestedInstallersHidden' -Default $false)
    $section.Visibility=if($hidden -or $Query.Trim()){'Collapsed'}else{'Visible'}
    if($section.Visibility -eq 'Collapsed' -and $section.Resources.Contains('untestedShowTimer')){
        $section.Resources['untestedShowTimer'].Stop();$section.Resources['untestedHideTimer'].Stop()
        $section.FindName('UntestedInstallerCloseOverlay').Visibility='Collapsed'
    }
}

function global:Initialize-UntestedInstallerSection {
    param($Window)
    $section=$Window.FindName('UntestedInstallerSection')
    if(-not $section -or $section.Resources.Contains('untestedInitialized')){return}
    # Give the self-contained section a lookup scope of its own as well as
    # the Window registrations used by scan, sizing and search.
    [Windows.NameScope]::SetNameScope($section,[Windows.NameScope]::new())
    foreach($name in @('UntestedGameList','UntestedInstallerSafetyStripe','UntestedInstallerTitle','UntestedInstallerCloseOverlay')){
        $section.RegisterName($name,$Window.FindName($name))
    }
    $section.Resources['untestedInitialized']=$true
    $section.Resources['untestedSessionHidden']=$false
    Set-UntestedInstallerCollapsed -Section $section -Collapsed ([bool](Get-HubSetting -Key 'untestedInstallersCollapsed' -Default $false))
    foreach($name in @('UntestedInstallerTitle','UntestedInstallerKind','UntestedInstallerDescription','UntestedInstallerCount')){
        $text=$Window.FindName($name);$text.Cursor=[Windows.Input.Cursors]::Hand
        $text.Resources['untestedSection']=$section
        $text.Add_PreviewMouseLeftButtonDown({
            param($sender,$event)
            $owner=$sender.Resources['untestedSection']
            Set-UntestedInstallerCollapsed -Section $owner -Collapsed (-not [bool]$owner.Resources['untestedCollapsed']) -Persist
            $event.Handled=$true
        })
    }
    $show=[Windows.Threading.DispatcherTimer]::new();$show.Interval=[TimeSpan]::FromSeconds(8)
    $hide=[Windows.Threading.DispatcherTimer]::new();$hide.Interval=[TimeSpan]::FromMilliseconds(800)
    $section.Resources['untestedShowTimer']=$show;$section.Resources['untestedHideTimer']=$hide
    $show.Tag=$section;$hide.Tag=$section
    $show.Add_Tick({
        $this.Stop();$owner=$this.Tag
        if($owner.IsVisible){$owner.FindName('UntestedInstallerCloseOverlay').Visibility='Visible'}
    })
    $hide.Add_Tick({$this.Stop();$this.Tag.FindName('UntestedInstallerCloseOverlay').Visibility='Collapsed'})
    $title=$Window.FindName('UntestedInstallerTitle')
    $title.Add_MouseEnter({
        $owner=$this.Resources['untestedSection'];$owner.Resources['untestedHideTimer'].Stop()
        if($owner.FindName('UntestedInstallerCloseOverlay').Visibility -ne 'Visible'){
            $owner.Resources['untestedShowTimer'].Stop();$owner.Resources['untestedShowTimer'].Start()
        }
    })
    $title.Add_MouseLeave({
        $owner=$this.Resources['untestedSection'];$owner.Resources['untestedShowTimer'].Stop()
        $owner.Resources['untestedHideTimer'].Start()
    })
    $overlay=$Window.FindName('UntestedInstallerCloseOverlay');$overlay.Resources['untestedSection']=$section
    $overlay.Add_MouseEnter({$this.Resources['untestedSection'].Resources['untestedHideTimer'].Stop()})
    $overlay.Add_MouseLeave({$this.Resources['untestedSection'].Resources['untestedHideTimer'].Start()})
    foreach($name in @('UntestedInstallerCloseBtn','UntestedInstallerDisableBtn')){
        $button=$Window.FindName($name);$button.Resources['untestedSection']=$section
        $button.Resources['untestedPermanent']=($name -eq 'UntestedInstallerDisableBtn')
        $button.Add_MouseLeftButtonUp({
            param($sender,$event)
            $owner=$sender.Resources['untestedSection'];$owner.Resources['untestedSessionHidden']=$true
            if($sender.Resources['untestedPermanent']){Set-HubSetting -Key 'untestedInstallersHidden' -Value $true}
            $owner.Resources['untestedShowTimer'].Stop();$owner.Resources['untestedHideTimer'].Stop()
            $owner.FindName('UntestedInstallerCloseOverlay').Visibility='Collapsed'
            $owner.Visibility='Collapsed';$event.Handled=$true
        })
        $button.Add_MouseEnter({$this.BorderBrush=[Windows.Media.BrushConverter]::new().ConvertFromString('#f3c741')})
        $button.Add_MouseLeave({$this.BorderBrush=[Windows.Media.BrushConverter]::new().ConvertFromString('#3a3a48')})
    }
    $section.Add_Unloaded({
        $this.Resources['untestedShowTimer'].Stop();$this.Resources['untestedHideTimer'].Stop()
    })
    Update-UntestedInstallerSectionVisibility -Window $Window
}
