function Get-AvJiraWorklog_Impl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Issue,
        [Parameter()]
        [datetime]
        $StartDate,
        [Parameter()]
        [datetime]
        $EndDate
    )
    process {

        $worklogCount = $issue.worklog.Total
        if (-not $worklogCount) {
            $worklogCount = $issue.WorklogCount
        }
        $counter = 0
        Write-WrappedProgress -Activity 'Parsing worklogs...' -Status 'Contacting server...' -child
        if (-not $EndDate) {
            $EndDate = [datetime]::MaxValue
        }
        $logs = Get-JiraIssueWorklog $issue.Key | 
            Select-Object -First $worklogCount | 
            Where-Object { $_.Started -ge $StartDate -and $_.started -lt $EndDate } | 
            ForEach-Object {
                Write-WrappedProgress -Activity 'Parsing worklogs...' -Status $item.Key -current $counter -Total $worklogCount -child
                [Worklog]::new($_,$Issue) 
                $counter++
            }
        Write-WrappedProgress -Activity 'Parsing worklogs...' -Completed -child
        
        $logs | Sort-Object Started -Descending
    }
}