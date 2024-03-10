$script:MainId = 1992
$script:AuxId = 1986
$script:ChildId = 2001

$script:MainBarParams = @{
    ID = $script:MainId
}
$script:ChildBarParams = @{
    ID       = $script:ChildId
    ParentID = $script:MainId
}
$script:AuxBarParams = @{
    ID = $script:AuxId
}
function Clear-WrappedProgress {
    Write-WrappedProgress -Activity 'Finished' -Completed -Auxiliary
    Write-WrappedProgress -Activity 'Finished' -Completed -child
    Write-WrappedProgress -Activity 'Finished' -Completed 
}
function Write-WrappedProgress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Activity,
        [Parameter()]
        [string]
        $Status,
        [Parameter()]
        [int]
        $Current = -1,
        [Parameter()]
        [int]
        $Total = -1,
        [Parameter()]
        [switch]
        $Child,
        [Parameter()]
        [switch]
        $Auxiliary,
        [Parameter()]
        [switch]
        $Completed
    )
    if ($Auxiliary.IsPresent) {
        $params = $AuxBarParams.clone()
    } else {
        $params = if ($child.IsPresent) { $script:ChildBarParams.Clone() } else { $script:MainBarParams.Clone() }
    }
    
    $params['Activity'] = $Activity
    $params['Status'] = if ([string]::IsNullOrWhiteSpace($Status)) { 'Processing...' } else { $Status }
    
    $percent = if ($Total -gt 0 -and $Current -ge 0) {
        $Current / $total * 100
    } else {
        -1
    }
    if ($percent -gt 100) {
        $percent = -1
    }
    $params['PercentComplete'] = $percent
    $params['Completed'] = $Completed.IsPresent
    Write-Progress @params
}