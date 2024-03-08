$script:DateChecked = Get-Date -Year 1970
$script:NewerInstalled = $false
$script:Interval = [timespan]::FromHours(24)
function Test-AvJiraUpdate {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $force
    )
    $timeSinceCheck = [datetime]::now - $script:DateChecked
    if ($script:NewerInstalled) {
        Write-Verbose 'Update already installed. Need to start a new PowerShell session'
        return
    }
    if ($timeSinceCheck -lt $script:Interval -and -not $force.IsPresent) {
        Write-Verbose "Already checked for updates on $($script:DateChecked) and found no updates."
        $timeToCheck = $script:Interval - $timeSinceCheck
        Write-Verbose "Next update check in $timeToCheck"
        return
    }
    Write-Verbose 'Looking for module updates.'
    $currentModule = Get-Module avjira -Verbose:$false
    $newestModule = Find-Module avjira -Repository 'PowershellSupportRepository' -Verbose:$false
    if ($newestModule.Version -gt $currentModule.Version) {
        Write-Warning "Updates to AvJira detected ($($currentModule.Version) -> $($newestModule.Version)). Starting update..."
        Update-Module AvJira -ea SilentlyContinue -Verbose:$false
        Write-Warning 'Update complete. You will still use the old version until PowerShell is restarted.'
        $script:NewerInstalled = $true
    } else {
        Write-Verbose 'No updates found.'
    }
    $script:DateChecked = Get-Date
}