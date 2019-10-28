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
    $ChkVpc = [bool](Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag*"} 4>$null)
    if (-not $ChkVpc) {
        Write-Verbose "$(Prefix)Creating new VPC with CIDR block $Network..."
        $vpc = New-EC2Vpc -CidrBlock $Network 4>$null
        Edit-EC2VpcAttribute -VpcId $vpc.VpcId -EnableDnsSupport $true 4>$null
        Edit-EC2VpcAttribute -VpcId $vpc.VpcId -EnableDnsHostnames $true 4>$null
        New-EC2Tag -Resource $vpc.VpcId -Tag $Tags 4>$null
    }
    else {Write-Warning "$(Prefix)A similar VPC might already exist!"}

} #function