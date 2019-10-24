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
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"}).VpcId
    #endregion

    # Create a new route table on our VPC so we can add a default route to it only
    # if one doesn't already exist for this VPC
    $IgwId = (Get-EC2InternetGateway @TagFilter).InternetGatewayId
    $rt    = Get-EC2RouteTable -Filter @{name='vpc-id' ; value = $VpcId}
    if (-not [bool]$rt) {
        Write-Verbose "$(Prefix)Creating the Route Table..."
        $rt = New-EC2RouteTable -VpcId $VpcId
    }
    Write-Verbose "$(Prefix)Setting static routes..."
    $params = @{
        RouteTableId         = $rt.RouteTableId
        GatewayId            = $IgwId
        DestinationCidrBlock = '0.0.0.0/0'
    }
    New-EC2Route @params | Out-Null
    New-EC2Tag -Resource $rt.RouteTableId -Tag $Tags
}