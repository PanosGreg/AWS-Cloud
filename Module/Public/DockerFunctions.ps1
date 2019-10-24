function Get-DockerImages {
    $list = docker images --no-trunc --format '{{json .}}' | ConvertFrom-Json
    $list | foreach {
        [pscustomobject] @{
            PSTypeName = 'Docker.Container.Images'
            Name       = $_.Repository
            Tag        = $_.Tag
            ID         = $_.Id.Substring(7)
            Created    = [datetime]::Parse($_.CreatedAt.Substring(0,19))
        }
    }
}

function Get-DockerPS {
    $list = docker ps --all --no-trunc --format '{{json .}}' | ConvertFrom-Json
    $list | foreach {
        $obj = [pscustomobject] @{
            PSTypeName     = 'Docker.Running.Images'
            Command        = $_.Command
            CreatedAt      = [datetime]::Parse($_.CreatedAt.Substring(0,19))
            ID             = $_.ID
            Image          = $_.Image
            Labels         = $_.Labels.split(',')
            LocalVolumes   = $_.LocalVolumes
            Mounts         = $_.Mounts.Split(',')
            Names          = $_.Names
            Networks       = $_.Networks.Split(',')
            Ports          = $_.Ports
            RunningFor     = $_.RunningFor
            Size           = $_.Size
            Status         = $_.Status
        }
        $DefaultSet        = 'Names','Command','Ports','Status'
        $DefaultDisplaySet = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet',[string[]]$DefaultSet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplaySet)
        $obj | Add-Member MemberSet PSStandardMembers $PSStandardMembers -PassThru
    }
}