function New-CustomNetworkAcl {
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
    @{key='Name' ;        value="$NameTag-NetworkACL"}
)
$VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"} 4>$null).VpcId
#endregion
    
Write-Verbose "$(Prefix)Creating the Network ACL..."
# First we need to remove the default ACL rules which allows everything
# when a new VPC is created, it creates a network ACL that's associated with it
# unfortunately we can't just delete the ACL and re-create it
# because it's the default ACL for this VPC, so we need to edit it.
$NaclId = (Get-EC2NetworkAcl -Filter @{name='vpc-id' ; value = $VpcId} 4>$null).NetworkAclId
# remove the 'allow all' inbound/outbound rules (egress=true/egress=false)
$params = @{
    NetworkAclId  = $NaclId
    RuleNumber    = 100
    Force         = $true
}
try {Remove-EC2NetworkAclEntry @params -Egress $true 4>$null} catch {$null}
try {Remove-EC2NetworkAclEntry @params -Egress $false 4>$null} catch {$null}

New-EC2Tag -Resource $NaclId -Tag $Tags 4>$null

# because NetworkACLs are stateless we need to specify both an inbound rule as well as
# an outbound rule. For example in the case of HTTP that's the ephemeral (random) port

ForEach ($rule in $AclRules.GetEnumerator()) {
    if ($rule.value) {
        New-CustomNetworkAclEntry -NaclId $NaclId -Connection $rule.key -Direction Inbound
    }
}
# Network ACLs are stateless, hence the following outbound rule
New-CustomNetworkAclEntry -NaclId $NaclId -Connection Random -Direction Outbound
}