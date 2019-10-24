function New-CustomSecurityGroup {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag,
    [hashtable]$AclRules
)
    
    #region --------------------- common variables
    $Tags = @(
        @{key='Environment' ; value=$EnvTag},
        @{key='Name' ;        value="$NameTag-SecurityGroup"}
    )
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"}).VpcId
    #endregion

    Write-Verbose "$(Prefix)Creating the Security Group..."
    $SgId = (Get-EC2SecurityGroup -Filter @{name='vpc-id' ; value = $VpcId}).GroupId
    New-EC2Tag -Resource $SgId -Tag $Tags

    # in security groups there is no action to allow or deny
    # hence each rule allows the specified traffic

    ForEach ($rule in $AclRules.GetEnumerator()) {
        if ($rule.value) {
            switch ($rule.key) {
                'HTTP'  {$Protocol = 'tcp'  ; $FromPort=80   ; $ToPort=80}
                'HTTPS' {$Protocol = 'tcp'  ; $FromPort=443  ; $ToPort=443}
                'RDP'   {$Protocol = 'tcp'  ; $FromPort=3389 ; $ToPort=3389}
                'WinRM' {$Protocol = 'tcp'  ; $FromPort=5985 ; $ToPort=5986}
                'ICMP'  {$Protocol = 'icmp' ; $FromPort=-1   ; $ToPort=-1}
            }
            $IpPerms            = [Amazon.EC2.Model.IpPermission]::new()
            $IpPerms.IpProtocol = $Protocol
            $IpPerms.FromPort   = $FromPort
            $IpPerms.ToPort     = $ToPort
            $IpPerms.IpRanges   = @('0.0.0.0/0')
            Grant-EC2SecurityGroupIngress -GroupId $SgId -IpPermissions $IpPerms | Out-Null
        }
    }
}