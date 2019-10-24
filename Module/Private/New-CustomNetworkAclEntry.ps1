function New-CustomNetworkAclEntry {
<#
.SYNOPSIS
    Helper function for creating Network ACLs
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet('HTTP','HTTPS','ICMP','RDP','WinRM','Random','DNS')]
    [string]$Connection,
    [ValidateSet('Inbound','Outbound')]
    [string]$Direction,
    [string]$NaclId
)

switch ($Direction) {
    'Inbound'  {$Egress = $false}
    'Outbound' {$Egress = $true}
}

switch ($Connection) {   # <-- TCP:6, 17:UDP, 1:ICMP, -1:All
    'HTTP'   {$Protocol = '6'}
    'HTTPS'  {$Protocol = '6'}
    'ICMP'   {$Protocol = '1'}
    'RDP'    {$Protocol = '6'}
    'WinRM'  {$Protocol = '6'}
    'DNS'    {$Protocol = '17'}
    'Random' {$Protocol = '-1'}
}

switch ($Connection) {
    'HTTP'   {$FromPort=80;$ToPort=80}
    'HTTPS'  {$FromPort=443;$ToPort=443}
    'ICMP'   {if     ($Direction -eq 'Inbound')  {$IcmpType=8}  # <-- Echo_Request = 8
              elseif ($Direction -eq 'Outbound') {$IcmpType=0}} # <-- Echo_Reply = 0
    'RDP'    {$FromPort=3389;$ToPort=3389}
    'WinRM'  {$FromPort=5985;$ToPort=5986}
    'DNS'    {$FromPort=53;$ToPort=53}
    'Random' {$FromPort=49152;$ToPort=65535}
}

$AllAclEntries = (Get-EC2NetworkAcl -NetworkAclId $NaclId).Entries
$DirectedAcls = $AllAclEntries.Where({$_.Egress -eq $Egress -and $_.RuleNumber -ne 32767}) 
$MaxAcl       = [int]($DirectedAcls | Measure-Object RuleNumber -Maximum).Maximum

$Params = @{
    NetworkAclId   = $NaclId
    Egress         = $Egress
    CidrBlock      = '0.0.0.0/0'
    Protocol       = $Protocol
    RuleAction     = ([Amazon.EC2.RuleAction]::Allow)
    RuleNumber     = $MaxAcl + 100
}

if ($Connection -eq 'ICMP') {
    $Params['IcmpTypeCode_Code'] = -1
    $Params['IcmpTypeCode_Type'] = $IcmpType
}
else {
    $Params['PortRange_From'] = $FromPort
    $Params['PortRange_To']   = $ToPort
}

New-EC2NetworkAclEntry @Params | Out-Null

} #function