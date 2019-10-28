function New-CustomRouteTable {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag
)

    #region --------------------- common variables
    $TagFilter = @{filter = @{name='tag:Name' ; value="$NameTag*"}}
    $Tags = @(
        @{key='Environment' ; value=$EnvTag},
        @{key='Name' ;        value="$NameTag-RouteTable"}
    )
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"} 4>$null).VpcId
    #endregion

    # Create a new route table on our VPC so we can add a default route to it only
    # if one doesn't already exist for this VPC
    $IgwId = (Get-EC2InternetGateway @TagFilter 4>$null).InternetGatewayId
    $rt    = Get-EC2RouteTable -Filter @{name='vpc-id' ; value = $VpcId} 4>$null
    if (-not [bool]$rt) {
        Write-Verbose "$(Prefix)Creating the Route Table..."
        $rt = New-EC2RouteTable -VpcId $VpcId 4>$null
    }
    Write-Verbose "$(Prefix)Setting static routes..."
    $params = @{
        RouteTableId         = $rt.RouteTableId
        GatewayId            = $IgwId
        DestinationCidrBlock = '0.0.0.0/0'
    }
    New-EC2Route @params 4>$null | Out-Null
    New-EC2Tag -Resource $rt.RouteTableId -Tag $Tags 4>$null
}