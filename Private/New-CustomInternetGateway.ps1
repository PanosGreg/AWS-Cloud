function New-CustomInternetGateway {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag
)

    #region --------------------- common variables
    $Tags = @(
        @{key='Environment' ; value=$EnvTag},
        @{key='Name' ;        value="$NameTag-Gateway"}
    )
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"} 4>$null).VpcId
    #endregion

    # Create the internet gateway that will act as a router for Internet traffic for
    # our VPC only if one isn't already attached to this VPC
    $ChkIgw = [bool](Get-EC2InternetGateway 4>$null | where { $_.Attachments.VpcId -eq $VpcId })
    if (-not $ChkIgw) {
        Write-Verbose "$(Prefix)Creating the Internet Gateway..."
        $igw = New-EC2InternetGateway 4>$null
        Add-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId -VpcId $VpcId 4>$null
        New-EC2Tag -Resource $igw.InternetGatewayId -Tag $Tags 4>$null
    }
    else {Write-Warning "$(Prefix)An Interntet Gateway is already attached to this VPC!"}
}