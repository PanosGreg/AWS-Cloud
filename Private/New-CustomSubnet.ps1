function New-CustomSubnet {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag,
    [string]$Subnet
)
    
    #region --------------------- common variables
    $Tags = @(
        @{key='Environment' ; value=$EnvTag},
        @{key='Name' ;        value="$NameTag-Subnet"}
    )
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"}).VpcId
    #endregion

    # Create the subnet and add it to the route table only if there's not a subnet created already
    $ChkSn = [bool](Get-EC2Subnet -Filter @{name='vpc-id' ; value = $VpcId})
    if (-not $ChkSn) {
        Write-Verbose "$(Prefix)Creating the Subnet $Subnet..."
        $az = Get-EC2AvailabilityZone
        $sn = New-EC2Subnet -VpcId $VpcId -CidrBlock $subnet -AvailabilityZone $az[0].ZoneName
        Edit-EC2SubnetAttribute -SubnetId $sn.SubnetId -AssignIpv6AddressOnCreation $false  # <-- this is the default but I just want to be explicit
        New-EC2Tag -Resource $sn.SubnetId -Tag $Tags
        $RtId = (Get-EC2RouteTable -Filter @{name='vpc-id' ; value = $VpcId}).RouteTableId
        Register-EC2RouteTable -RouteTableId $RtId -SubnetId $sn.SubnetId | Out-Null
    }
    else {Write-Warning "$(Prefix)A subnet is already attached to this VPC!"}

}