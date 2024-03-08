$script:MainId = 2006
$script:ChildId = 1969

$script:MainBarParams = @{
    ID = $script:MainId
}
$script:ChildBarParams = @{
    ID       = $script:ChildId
    ParentID = $script:MainId
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
        $Completed
    )
    $params = if ($child.IsPresent) { $script:ChildBarParams.Clone() } else { $script:MainBarParams.Clone() }
    
    $params['Activity'] = $Activity
    $params['Status'] = if ([string]::IsNullOrWhiteSpace($Status)) { $Activity } else { $Status }
    
    $percent = if ($Total -gt 0 -and $Current -ge 0) {
        $Current / $total * 100
    } else {
        -1
    }
    if ($percent -gt 100) {
        $percent = -1
    }
    $params['-PercentComplete'] = $percent
    $params['Completed'] = $Completed.IsPresent
    Write-Progress @params
}