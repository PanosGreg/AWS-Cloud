function Get-CustomInstanceDetails {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag
)
    
$VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"}).VpcId    

$SubnetId    = (Get-EC2Subnet -Filter @{name='vpc-id' ; value = $VpcId}).SubnetId
$Reservation = Get-EC2Instance -Filter @{Name="vpc-id";Value=$VpcId},
                                       @{Name="subnet-id";Value=$SubnetId},
                                       @{Name="tag:Name";Value="$NameTag-Instance"}
$Instance = $Reservation.Instances
$PemFile = Join-Path -Path $env:TEMP -ChildPath "$NameTag-Key.pem"
if (Test-Path $PemFile) {
    $Password = $null
    while ($true) {
        if ($Password -eq $null) {
            Write-Verbose "$(Prefix)Waiting 30sec for password to be available..."
            Start-Sleep -Seconds 30
            $Password = Get-EC2PasswordData -InstanceId $Instance.InstanceId -PemFile $PemFile -Decrypt 3>$null
        }
        else {Break}
    }
    $SecurePass = ConvertTo-SecureString -String $Password -AsPlainText -Force
}
else {Throw 'The PEM file was not found!'}
$Creds = [System.Management.Automation.PSCredential]::new('administrator',$SecurePass)
$Obj = [pscustomobject] @{
    Name       = $NameTag
    Ipaddress  = $Instance.PublicIpAddress
    Credential = $Creds
}

Write-Output $Obj

}