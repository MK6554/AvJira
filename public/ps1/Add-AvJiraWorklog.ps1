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
        
    $local:outside_checkPerformed = $true # will skip session test for any subcommands
    $null = $local:outside_checkPerformed # to silence warnings about unused variable

    while (-not $issue) {
        $Issue = Read-Host 'Enter issue ID'
        if (-not $Issue) { Write-Host 'Issue cannot be empty' }
    }
    if (-not $Comment) {
        $Comment = Read-Host 'Enter work log comment'
    } 

    $Time = Get-ParsedTime $Time
    $Date = Get-ParsedDate $Date
    
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


