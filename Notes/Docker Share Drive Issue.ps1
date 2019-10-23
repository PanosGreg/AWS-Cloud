

## Docker gives an error when trying to share a drive in Windows
## the error message is: 

# Firewall detected
# A firewall is blocking file Sharing between Window sand the containers.

# the following steps solved the issue.
# Note: I had to go through all of the below to make it work
# (carpet bombing approach as someone commented in StackOverflow)

# add a rule in windows firewall to allow traffic for docker
$params = @{
    Name          = 'DockerSmbMount'
    DisplayName   = 'DockerSmbMount'
    Enabled       = 'True'
    Profile       = 'Any'
    Direction     = 'Inbound'
    Action        = 'Allow'
    LocalAddress  = '10.0.75.1/32'
    RemoteAddress = '10.0.75.2/32'
    Protocol      = 'TCP'
    LocalPort     = '445'
}
New-NetFirewallRule @params | Out-Null

# set docker network profile to private (from public)
Set-NetConnectionProfile -InterfaceAlias "vEthernet (DockerNAT)" -NetworkCategory 'Private'


# reset the File and Print Sharing service on the Docker vNIC
Disable-NetAdapterBinding -Name "vEthernet (DockerNAT)" -ComponentID ms_server
Enable-NetAdapterBinding -Name "vEthernet (DockerNAT)" -ComponentID ms_server

# reset the type of the Docker vSwitch
Set-VMSwitch -Name 'DockerNAT' -SwitchType Private -Confirm:$false
Set-VMSwitch -Name 'DockerNAT' -SwitchType Internal -Confirm:$false

# restart the Docker VM
Stop-VM DockerDesktopVM -Force -Confirm:$false 
Start-VM DockerDesktopVM

# restart the docker services
Stop-Service -Name 'com.docker.service' -Confirm:$false -Force
Stop-Service -Name 'docker' -Confirm:$false -Force
Get-Process *docker* | Stop-Process -Force -Confirm:$false
Start-Service -Name 'com.docker.service'
Start-Service 'docker'
& "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Go to Docker Settings and reset the credentials

# Finally share the drive