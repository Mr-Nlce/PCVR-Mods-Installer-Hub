# Resolve Microsoft Store games from public Windows registration. No game
# manifests, protected folders, ownership changes or guessed application IDs.
function Get-PCVRXboxLaunchRegistration {
    param([string]$GameRoot,[string[]]$Names=@())
    $result=[pscustomobject]@{IsXbox=$false;AppId=$null;Source=$null}
    if([string]::IsNullOrWhiteSpace($GameRoot)){return $result}
    $root=[IO.Path]::GetFullPath($GameRoot).TrimEnd([char[]]'\/')
    if($root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return $result}
    $result.IsXbox=$root -match '(?i)[\\/](?:XboxGames|WindowsApps)[\\/]'
    $packages=@()
    try{$packages=@(Get-AppxPackage -ErrorAction Stop | Where-Object {
        if(-not $_.InstallLocation -or -not $_.PackageFamilyName){return $false}
        $location=([string]$_.InstallLocation).TrimEnd([char[]]'\/')
        $root.Equals($location,[StringComparison]::OrdinalIgnoreCase) -or
            $root.StartsWith($location+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
    })}catch{}
    if($packages.Count){$result.IsXbox=$true}
    if(-not $result.IsXbox){return $result}
    $apps=@()
    try{
      $registeredApps=@(Get-StartApps -ErrorAction Stop)
      # Whole-wrapper integration replaces only the public Windows response,
      # never a production path, game payload or launch implementation.
      if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_STORE_TEST_APPS){
        $testFile=[IO.Path]::GetFullPath($env:PCVR_STORE_TEST_APPS)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $testFile.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path (Split-Path $testFile) '.pcvr_store_fixture'))){throw 'Store registration fixture is not isolated.'}
        $registeredApps=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($testFile))
      }
      $apps=@($registeredApps | Where-Object {
        # Start menu also contains ordinary Steam shortcuts. Only packaged
        # application identities can be passed to AppsFolder activation.
        [string]$_.AppID -match '^[^\\/!]+_[a-z0-9]{13}![^\\/!]+$'
    })}catch{}
    if($packages.Count){
        $apps=@($apps | Where-Object {
            $id=[string]$_.AppID
            @($packages | Where-Object {$id.StartsWith(([string]$_.PackageFamilyName+'!'),[StringComparison]::OrdinalIgnoreCase)}).Count -gt 0
        })
        $result.Source='Windows package registration'
    }else{
        # A known XboxGames location can use its exact Start menu name when
        # Gaming Services does not expose InstallLocation. Never fuzzy-match.
        $apps=@($apps | Where-Object { [string]$_.Name -in $Names })
        $result.Source='Windows Start menu'
    }
    if($apps.Count -gt 1){
        $exact=@($apps | Where-Object {[string]$_.Name -in $Names})
        if($exact.Count -eq 1){$apps=$exact}
    }
    $ids=@($apps | ForEach-Object {[string]$_.AppID} | Where-Object {$_} | Select-Object -Unique)
    if($ids.Count -eq 1){$result.AppId=[string]$ids[0]}
    return $result
}

function Start-PCVRXboxApplication {
    param([Parameter(Mandatory)][string]$AppId,[string]$Arguments='')
    if($AppId -notmatch '^[^\\/!]+_[a-z0-9]{13}![^\\/!]+$'){throw 'Windows did not provide a valid Xbox application identity.'}
    if(-not $Arguments){
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('shell:AppsFolder\'+$AppId) -ErrorAction Stop
        return
    }
    # The documented Windows activation API accepts application arguments;
    # explorer's AppsFolder command does not forward renderer options.
    if(-not ('PCVR.StoreActivation' -as [type])){
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace PCVR {
 [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IApplicationActivationManager {
  [PreserveSig] int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appId, [MarshalAs(UnmanagedType.LPWStr)] string arguments, uint options, out uint processId);
  [PreserveSig] int ActivateForFile(IntPtr appId, IntPtr items, IntPtr verb, out uint processId);
  [PreserveSig] int ActivateForProtocol(IntPtr appId, IntPtr items, out uint processId);
 }
 public static class StoreActivation {
  public static uint Launch(string appId, string arguments) {
   object instance=Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("45ba127d-10a8-46ea-8ab7-56ea9078943c")));
   try {uint pid; int hr=((IApplicationActivationManager)instance).ActivateApplication(appId,arguments,0,out pid); Marshal.ThrowExceptionForHR(hr); return pid;}
   finally {Marshal.FinalReleaseComObject(instance);}
  }
 }
}
'@
    }
    [void][PCVR.StoreActivation]::Launch($AppId,$Arguments)
}

function Get-PCVRStoreGameNames {
    param($Game)
    $names=@($Game.XboxAppNames)+@($Game.SteamFolder)
    $names+=([string]$Game.Title -replace '\s+VR(?:\s*-.*)?$','')
    return @($names | Where-Object {$_} | Select-Object -Unique)
}
