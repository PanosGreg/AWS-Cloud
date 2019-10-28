function Wait-CustomInstanceState {
[OutputType('void')]
[CmdletBinding()]
param
(
    [string]$InstanceId,
    [ValidateSet('running','stopped')]
    [string]$DesiredState,
    [int]$RetryInterval = 5
)

    while ($true) {
        $obj = Get-EC2InstanceStatus -IncludeAllInstance $true -InstanceId $InstanceId
        $status = $obj.InstanceState.Name.Value
        if ($status -eq $DesiredState) {Write-Verbose "$(Prefix)Instance started!";Break}
        else {
            Write-Verbose "$(Prefix)Waiting for the instance to start..."
            Start-Sleep -Seconds $RetryInterval            
        }
    }
}