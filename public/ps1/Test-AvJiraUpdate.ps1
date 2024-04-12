function Test-AvJiraUpdate {
    <#
    .SYNOPSIS
        Checks if there is an updated version of the module and installs it.
    .DESCRIPTION
        Checks if there is an updated version of the module and installs it. The cmdlet will check once in 24 hours.
    .PARAMETER Force
        Forces a recheck, even if it was checked not to long ago.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Force
    )
    if ($outside_checkPerformed -and -not $force.IsPresent) {
        return
    }
    $timeSinceCheck = [datetime]::now - $script:DateChecked
    if ($script:NewerInstalled) {
        Write-Log 'Update already installed. Need to start a new PowerShell session'
        return
    }
    if ($timeSinceCheck -lt $script:Interval -and -not $force.IsPresent) {
        Write-Log "Already checked for updates on $($script:DateChecked) and found no updates."
        $timeToCheck = $script:Interval - $timeSinceCheck
        Write-Log "Next update check in $timeToCheck"
        return
    }
    Write-WrappedProgress -Activity 'Checking for module updates...' -Auxiliary
    Update-Biedametry $MyInvocation.MyCommand.Name $PSBoundParameters
    $currentModule = Get-Module avjira -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
    $newestModule = Find-Module avjira -Repository 'PowershellSupportRepository' -Verbose:$false -ea SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
    if ($newestModule.Version -gt $currentModule.Version) {
        Write-Log "Updates to AvJira detected ($($currentModule.Version) -> $($newestModule.Version)). Starting update..." -warning
        Update-Module AvJira -ea SilentlyContinue -Verbose:$false
        Write-Log 'Update complete. You will still use the old version until PowerShell is restarted.' -Warning
        $script:NewerInstalled = $true
    } else {
        Write-Log 'No updates found.'
    }
    Write-WrappedProgress -Activity 'Checking for module updates...' -Completed -Auxiliary
    $script:DateChecked = Get-Date
}