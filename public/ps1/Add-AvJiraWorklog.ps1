function Add-AvJiraWorklog {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Issue,
        [Parameter()]
        [string]
        $Comment,
        [Parameter()]
        [nullable[datetime]]
        [JiraDateTimeConverterAttribute()]
        $Date,
        [Parameter()]
        [JiraTimeSpanConverterAttribute()]
        [nullable[timespan]]
        $Time
    )
    Test-AvJiraSession
    while (-not $issue) {
        $Issue = Read-Host 'Enter issue ID'
        if (-not $Issue) { Write-Host 'Issue cannot be empty' }
    }
    if (-not $Comment) {
        $Comment = Read-Host 'Enter work log comment'
    } 
    if (-not $Time) {
        while ($true) {
            $temp = Read-Host 'Enter time spent'
            try {
                $Time = [JiraTimeSpanConverterAttribute]::new().Transform($null, $temp)
                break
            } catch [System.ArgumentException] {
                Write-Host "$temp was not invalid time format. Try again (hh:mm:ss or hhmmss)."
            }
        }
    } 
    if (-not $Date) {
        $now = [datetime]::now
        while ($true) {
            $temp = Read-Host "Enter date of work (leave empty to use current date: $now))"
            if ($temp -notmatch '[\d-:]+') {
                $Date = $now
                break
            } else {
                try {
                    $Date = [JiraDateTimeConverterAttribute]::new().Transform($null, $temp)
                    break
                } catch [System.ArgumentException] {
                    Write-Host "$temp was not a valid date. Try again (yyyy-mm-dd)."
                }
            }
        }
    }
    $log = @{
        Comment     = $Comment
        Issue       = $Issue
        TimeSpent   = $Time
        DateStarted = $date
    }
    $logDisplay = $log.Clone()
    $logDisplay['TimeSpent'] = $Time.tostring('hh\h\ mm\m')
    Write-Host 'Log to add:'
    ([pscustomobject]$logDisplay) | Format-List | Out-String
    Read-Host 'Press ENTER to add or CTRL-Z to cancel'
    Add-JiraIssueWorklog @log  
}
