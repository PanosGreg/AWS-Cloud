function New-CustomKeyPair {
    <#
    
    #>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag
)

    # Create the key pair that will be used to get the login credentials for windows
    $kp = try {Get-EC2KeyPair -KeyName "$NameTag-Key" 4>$null} catch {$null}
    if (-not [bool]$kp) {
        Write-Verbose "$(Prefix)Creating the Key Pair..."
        $kp = New-EC2KeyPair -KeyName "$NameTag-Key" 4>$null
    }
    Write-Verbose "$(Prefix)Creating the Certificate file..."
    $PemFile = Join-Path -Path $env:TEMP -ChildPath "$NameTag-Key.pem"
    $kp.KeyMaterial | Out-File -Encoding ascii -FilePath $PemFile
    # Key Pairs can not be tagged, they have their name which can be used to look for them
}