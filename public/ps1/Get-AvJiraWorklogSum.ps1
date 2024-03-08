function Get-AvJiraWorklogSum {
    <#
    .SYNOPSIS
        Sums given logs up.
    .DESCRIPTION
        Return total time spent from given logs. This cmdlet should be used in pipeline (with the | operator)
    .EXAMPLE
        get-avjiraworklog | logsum
    #>
    
    [CmdletBinding()]
    [Alias('logsum')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Worklog[]]
        $Worklog
    )
    begin {
        $logs = [System.Collections.Generic.List[Worklog]]::new()
    }
    process {
        foreach ($w in $Worklog) {
            $logs.Add($w)
        }
    }
    end {
        $s = [SummedWorklogs]::new($logs.Toarray())
        [PSCustomObject][ordered]@{
            LogCount  = $s.Worklogs.count
            Issues    = $s.Issue.Count
            TotalTime = $s.TimeSpentTotal
        }
    }
}