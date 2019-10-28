function Get-AmazonMachineImage {
<#

#>
[CmdletBinding()]
param (
    [string]$OsType
)

    Write-Verbose "$(Prefix)Getting the Amazon Machine Image..."
    $versions = '1903','2019'   # <-- update these entries as new versions come out from Microsoft
    $Imgs = foreach ($ver in $versions) {
        $filters = @(
            @{Name = 'platform' ; Values = 'windows'}
            @{name='name' ; values="*$ver*English*Base*"}  # alt: 2019|1903, Base|ECS|*
        )
        $AllWin = Get-EC2Image -Owners amazon -Filters $filters | where name -notlike *sql*
        $AllWin | foreach {
            $CreationDate =  $_.CreationDate.Substring(0,19)
            [pscustomobject] @{
                Name         = $_.Name
                ImageId      = $_.ImageId
                CreationDate = [datetime]::Parse($CreationDate)
            }
        }
    }
    if ($OsType -eq 'Core') {$ver = '1903'}
    if ($OsType -eq 'Full') {$ver = '2019'}

    # get the latest one
    $AMI = $Imgs | sort creationdate -Descending | where name -like "*$ver*$OsType*" | select -First 1

    Write-Output $AMI
}