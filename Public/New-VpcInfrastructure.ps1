function New-VpcInfrastructure {
<#
.SYNOPSIS
    Creates a new Virtual Private Cloud (VPC) in AWS, along with all pre-requisite resources
.DESCRIPTION
    This function assumes the folliwing things:
    - You'll be using a Windows Image of the latest version
    - DNS support for the VPC is enabled
    - The function will wait until the resources have been provisioned in AWS
    - The availability zone for the subnet is always the first option from the list
      of your region
    - this VPC only has one subnet
    - the instance types are based on the t3a family of instances
    [EU Ireland Region Prices]
    Instance    Cores   RAM     Cost/Hr
    t3a.micro    2c     1GB      ¢1.94
    t3a.small    2c     2GB      ¢3.88
    t3a.medium   2c     4GB      ¢5.92
    t3a.large    2c     8GB     ¢10.92
    t3a.xlarge   4c    16GB     ¢23.68
.EXAMPLE
    $params = @{
        Name        = 'MyLab'
        VmSize      = 'small'
        Network     = '10.0.0.0/22'
        Subnet      = '10.0.1.0/24'
        Environment = 'Test'
        AllowRDP    = $true
        AllowPing   = $true
        OsType      = 'Core'
    }
    $details = New-VpcInfrastructure @params -Verbose    
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Name,
    [ValidateSet('Micro','Small','Medium','Large','XtraLarge')]
    [string]$VmSize = 'Medium',
    [string]$Network = '10.0.0.0/22',
    [string]$Subnet = '10.0.1.0/24',
    [string]$Environment = 'Test',
    [switch]$AllowRDP,
    [switch]$AllowWinRM,
    [switch]$AllowPing,
    [switch]$AllowHTTP,
    [ValidateSet('Core','Full')]
    [string]$OsType = 'Core'
)

Begin {

    $TagParams = @{
        NameTag = $Name
        EnvTag  = $Environment
    }

    if ([bool](Get-DefaultAWSRegion)) {
        throw 'Please set a default AWS region to work with!'
    }

} #begin

Process {

    # --------------------- create the VPC and enable DNS resolution
    New-CustomVpc @TagParams -Network $Network

    # --------------------- create an internet gateway and attach it to the vpc
    New-CustomInternetGateway @TagParams
 
    # --------------------- create default static route
    New-CustomRouteTable @TagParams

    # --------------------- create subnet and set the routing 
    New-CustomSubnet @TagParams -Subnet $Subnet

    # --------------------- create a key pair and its certificate file
    New-CustomKeyPair @TagParams

    # --------------------- collect the firewall rules into a hashtable 
    $AclRules = @{
        HTTP  = [bool]$AllowHTTP
        HTTPS = [bool]$AllowHTTP  # <-- the HTTP option sets both the HTTP and the HTTPS firewall rules
        RDP   = [bool]$AllowHTTP
        WinRM = [bool]$AllowWinRM
        ICMP  = [bool]$AllowPing
    }

    # --------------------- create the network acl and its firewall rules
    New-CustomNetworkAcl @TagParams -AclRules $AclRules
 
    # --------------------- create the security group and its firewall rules
    New-CustomSecurityGroup @TagParams -AclRules $AclRules

    # --------------------- get the image
    $ImageId = (Get-AmazonMachineImage -OsType $OsType).ImageId

    # --------------------- create the instance
    New-CustomInstance @TagParams -ImageId $ImageId -VmSize $VmSize

    # --------------------- get the IP and password to login
    $Output = Get-CustomInstanceDetails @TagParams

} #process

End {

    Write-Output $Output

}


} #function