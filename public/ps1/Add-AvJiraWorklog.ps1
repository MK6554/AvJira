function Add-AvJiraWorklog {
    <#
    .SYNOPSIS
        Adds a new worklog to the speicified issue.
    .DESCRIPTION
        Adds a new worklog to the speicified issue. Creates the log from input parameter or interactively. Will ask for confirmation.
    .PARAMETER Issue
        Issue ID to add a worklog to.
    .PARAMETER Comment
        Optional description of log.
    .PARAMETER Date
        Date at which the work was started. 
    .PARAMETER Time
        How long the work took.
    .PARAMETER Force
        If specified, will NOT ask for confimation.
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
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
        $Time,
        [Parameter()]
        [switch]
        $Force
    )
    
    $local:outside_checkPerformed = $true # will skip session test for any subcommands
    $null = $local:outside_checkPerformed # to silence warnings about unused variable
    $interactive = -not $time -or -not $Issue -or -not $date
    $Time = Get-ParsedTime $Time
    
    $Date = Get-ParsedDate $Date
    
    while (-not $issue) {
        $Issue = Read-Host 'Enter issue ID'
        if (-not $Issue) { Write-Host 'Issue cannot be empty' }
    }
    if (-not $Comment -and $interactive) {
        $Comment = Read-Host 'Enter work log comment'
    } 
    
    
    $log = @{
        Comment     = $Comment
        Issue       = $Issue
        TimeSpent   = $Time
        DateStarted = $date
    }
    $logDisplay = $log.Clone()
    $logDisplay['TimeSpent'] = $Time.tostring('hh\h\ mm\m')
    $logStr = ([pscustomobject]$logDisplay) | Format-List | Out-String
    if ($PSCmdlet.ShouldContinue('Do you want to add this log?', $logStr) -or $force.IsPresent) {
        Get-AvJiraSession
        Add-JiraIssueWorklog @log  
        Update-Biedametry $MyInvocation.MyCommand.Name $PSBoundParameters
    }
    Write-Log "$($MyInvocation.MyCommand.Name) finished."
}


