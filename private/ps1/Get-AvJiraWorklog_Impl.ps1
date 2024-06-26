function Get-AvJiraWorklog_Impl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Issue, # get-jiraissue psoobject or [Issue]
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
        # is a psobject
        $worklogCount = $issue.worklog.Total
        if (-not $worklogCount) {
            # is an issue
            $worklogCount = $issue.WorklogCount
        }
        if($worklogCount -le 0){
            # PowerShell 5 will bug out when fetching worklogs of issue with no worlogs, here we skip it.
            return
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