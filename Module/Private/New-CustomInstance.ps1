function New-CustomInstance {
<#

#>
[CmdletBinding()]
param (
    [string]$NameTag,
    [string]$EnvTag,
    [string]$ImageId,
    [string]$VmSize
)
    
#region --------------------- common variables
$Tags = @(
    @{key='Environment' ; value=$EnvTag},
    @{key='Name' ;        value="$NameTag-Instance"}
)
$VpcId = (Get-EC2Vpc -Filter @{name='tag:Name' ; value="$NameTag"}).VpcId    
#endregion

        
#region --------------------- create the instance
Write-Verbose "$(Prefix)Creating the instance..."
$SubnetId                = (Get-EC2Subnet -Filter @{name='vpc-id' ; value = $VpcId}).SubnetId
$SecGrpId                = (Get-EC2SecurityGroup -Filter @{name='vpc-id' ; value = $VpcId}).GroupId
$bdm                     = [Amazon.EC2.Model.BlockDeviceMapping]::new()
$bdm.DeviceName          = '/dev/sda1'
$ebs                     = [Amazon.EC2.Model.EbsBlockDevice]::new()
$ebs.VolumeSize          = '40'
$ebs.VolumeType          = 'gp2'
$ebs.DeleteOnTermination = $true
$bdm.Ebs                 = $ebs
$nispec                  = [Amazon.EC2.Model.InstanceNetworkInterfaceSpecification]::new()
$nispec.SubnetId         = $SubnetId
$nispec.DeviceIndex      = 0
$nispec.Groups.Add($SecGrpId)
$nispec.AssociatePublicIpAddress = $true
$AvailabilityZone        = (Get-EC2AvailabilityZone)[0].ZoneName
$KeyName                 = (Get-EC2KeyPair -KeyName "$NameTag-Key").KeyName

switch ($VmSize) {
    'Micro'      {$InstanceType = 't3a.micro'}
    'Small'      {$InstanceType = 't3a.small'}
    'Medium'     {$InstanceType = 't3a.medium'}
    'Large'      {$InstanceType = 't3a.large'}
    'XtraLarge'  {$InstanceType = 't3a.xlarge'}
}

$params = @{
    ImageId            = $ImageId
    MinCount           = 1
    MaxCount           = 1
    KeyName            = $KeyName
    InstanceType       = $InstanceType
    NetworkInterface   = $nispec
    AvailabilityZone   = $AvailabilityZone
    BlockDeviceMapping = $bdm
    #SecurityGroupId    = $sg.GroupId
    #SubnetId           = $sn.SubnetId
    #AssociatePublicIp  = $true
}

$reservation = New-EC2Instance @params
$instance = $reservation.Instances
New-EC2Tag -Resource $instance.InstanceId -Tag $Tags
Wait-CustomInstanceState -InstanceId $instance.InstanceId -DesiredState 'running'
#endregion

}