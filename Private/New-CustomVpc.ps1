function New-CustomVpc {
<#
.SYNOPSIS
#>

[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag,
    [string]$Network
)
    #region --------------------- common variables
    $Tags = @(
        @{key='Environment' ; value=$EnvTag},
        @{key='Name' ;        value="$NameTag"}
    )
    #endregion

    # Create the VPC only if one doesn't already exist with the same tag
    $ChkVpc = [bool](Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag*"})
    if (-not $ChkVpc) {
        Write-Verbose "$(Prefix)Creating new VPC with CIDR block $Network..."
        $vpc = New-EC2Vpc -CidrBlock $Network
        Edit-EC2VpcAttribute -VpcId $vpc.VpcId -EnableDnsSupport $true
        Edit-EC2VpcAttribute -VpcId $vpc.VpcId -EnableDnsHostnames $true
        New-EC2Tag -Resource $vpc.VpcId -Tag $Tags
    }
    else {Write-Warning "$(Prefix)A similar VPC might already exist!"}

} #function