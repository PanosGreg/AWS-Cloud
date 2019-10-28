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
    $VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"} 4>$null).VpcId
    #endregion

    # Create the subnet and add it to the route table only if there's not a subnet created already
    $ChkSn = [bool](Get-EC2Subnet -Filter @{name='vpc-id' ; value = $VpcId} 4>$null)
    if (-not $ChkSn) {
        Write-Verbose "$(Prefix)Creating the Subnet $Subnet..."
        $az = Get-EC2AvailabilityZone 4>$null
        $sn = New-EC2Subnet -VpcId $VpcId -CidrBlock $subnet -AvailabilityZone $az[0].ZoneName 4>$null
        Edit-EC2SubnetAttribute -SubnetId $sn.SubnetId -AssignIpv6AddressOnCreation $false 4>$null  # <-- this is the default but I just want to be explicit
        New-EC2Tag -Resource $sn.SubnetId -Tag $Tags 4>$null
        $RtId = (Get-EC2RouteTable -Filter @{name='vpc-id' ; value = $VpcId} 4>$null).RouteTableId
        Register-EC2RouteTable -RouteTableId $RtId -SubnetId $sn.SubnetId 4>$null | Out-Null
    }
    else {Write-Warning "$(Prefix)A subnet is already attached to this VPC!"}

}