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
        $EndDate,
        [Parameter()]
        [string[]]
        $Authors
    )
    process {

        $worklogCount = $issue.worklog.Total
        if (-not $worklogCount) {
            $worklogCount = $issue.WorklogCount
        }
        $counter = 0
        if (-not $EndDate) {
            $EndDate = [datetime]::MaxValue
        }
        Get-JiraIssueWorklog $issue.Key | 
            Select-Object -First $worklogCount | 
            Where-Object { $_.Started -ge $StartDate -and $_.started -lt $EndDate -and (Test-Author $_.Author $Authors) } | 
            ForEach-Object {
                $counter++
                Write-WrappedProgress -Activity 'Getting worklogs...' -Status $item.Started -current $counter -Total $worklogCount -child
                [Worklog]::new($_, $Issue) 
            }
    }
}

function Test-Author {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]
        $Author,
        [Parameter()]
        [string[]]
        $Authors
    )
    if (-not $Authors) {
        $true
    } else {
        $Authors -contains $Author.Name -or $Authors -contains $Author.DisplayName
    }
}