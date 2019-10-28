
function Get-Hash($InputObject) {
    $InStr = [management.automation.psserializer]::Serialize($InputObject)
    $algo  = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($InStr)
    $StrB  = [System.Text.StringBuilder]::new()
    $algo.ComputeHash($bytes) | foreach {[void]$StrB.Append($_.ToString('x2'))}
    $Hash  = $StrB.ToString()
    Write-Output $Hash
}

Function Test-IsAdmin {
<#
.Synopsis
    Checks if the current console session is running elevated (with admin privileges) or not
#>
    $CurrentId = [Security.Principal.WindowsIdentity]::GetCurrent()
    $AdminRole = [Security.Principal.WindowsBuiltinRole]::Administrator
    $IsAdmin   = [Security.Principal.WindowsPrincipal]::new($CurrentId).IsInRole($AdminRole)
    Write-Output $IsAdmin
}

function Prefix {
<#
.SYNOPSIS
    Outputs a small string with a timestamp that can be used as a prefix in log files
.EXAMPLE
    # in a function, when writing verbose messages, add this prefix
    Write-Verbose "$(Prefix)Script started"  # --> [DESKTOP 12/03/2018 15:31:42]::Script Started
#>
    "[$env:COMPUTERNAME $([datetime]::Now.ToString('dd/MM/yy HH:mm:ss'))]::"
}