

# Install Terminalizer

# Steps:
# 1) install chocolatey
# 2) then install node.js
# 3) then install terminalizer

$Scriptblock = {
    $LogFile = '{0}\Installation_{1}.log' -f $env:TEMP,[datetime]::Now.Date.ToString('dd.MM.yy')
    Start-Transcript -Path $LogFile
    $Stopwatch = [system.diagnostics.stopwatch]::StartNew()

    #region ----------------------------------------------------------- Install Chocolatey
    if (Test-Path C:\ProgramData\chocolatey\bin\choco.exe) {Write-Output 'Choco already exists'}
    else {
        $ChocoURL  = 'https://chocolatey.org/install.ps1'
        $ChocoPS1  = [System.Net.WebClient]::new().DownloadString($ChocoUrl)
        Invoke-Expression $ChocoPS1
        $ChocoInstaller = Join-Path $env:ChocolateyInstall 'helpers\chocolateyInstaller.psm1'
        $ChocoProfiler  = Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
        Import-Module $ChocoInstaller    # --> this gives refreshenv among other things
        Import-Module $ChocoProfiler     # --> this gives the tab expansion for choco
        refreshenv
        Write-Output 'Chocolatey has been installed'
    }
    #endregion

    #region ----------------------------------------------------------- Install Node & Terminalizer
    choco install nodejs.install --version 10.16.0 -y   # --> latest ver. as of 24/07/19
    refreshenv
    Write-Output 'Node.js has been installed'
    npm install -g terminalizer
    Write-Output 'Terminalizer has been installed'
    #endregion

    [ordered]@{Chocolatey=(choco -v);Node=(node -v);NPM=(npm -v);Terminalizer=(terminalizer -v)}
    $stopwatch.stop()
    Write-Output "Total script runtime: $([int]$stopwatch.Elapsed.TotalSeconds) seconds"
    Stop-Transcript
}

if ($PSVersionTable.PSVersion.ToString(2) -lt '5.1') {
    Throw 'This script requires PowerShell version 5.1 or later to work'
}

$AdminRole   = [Security.Principal.WindowsBuiltInRole]::Administrator
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdmin     = [Security.Principal.WindowsPrincipal]::new($CurrentUser).IsInRole($AdminRole)
$LogFile     = '{0}\Installation_{1}.log' -f $env:TEMP,[datetime]::Now.Date.ToString('dd.MM.yy')

if (-not $IsAdmin) {
    $ByteCommand = [System.Text.encoding]::Unicode.GetBytes($Scriptblock)
    $EncodedCmd  = [convert]::ToBase64string($ByteCommand)
    $ArgList     = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCmd"

    Write-Warning "Logfile to be created: $LogFile"
    Write-Warning 'The following will show a UAC prompt'
    Start-Sleep -Seconds 2
    Start-Process Powershell.exe -Verb RunAs -ArgumentList $ArgList
}
else {
    $Scriptblock.Invoke()
}