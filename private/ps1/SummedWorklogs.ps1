class SummedWorklogs {
    [Worklog[]]$Worklogs
    [timespan]$TimeSpentTotal
    [string[]]$Issue
    SummedWorklogs([Worklog[]]$logs) {
        $this.Worklogs = $logs
        $this.TimeSpentTotal = $logs | Measure-Object -Sum -Property TimeSpentSeconds | ForEach-Object { [timespan]::FromSeconds([int]($_.Sum)) }
        $this.Issue = $logs | ForEach-Object { $_.Issue.FullName } | Select-Object -Unique
    }
}