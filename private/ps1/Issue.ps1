class Issue {
    [string]$Key
    [string]$Name
    [Person]$Reporter
    [Person]$Creator
    [Person]$Asignee
    [string[]]$Status
    [timespan]$TimeSpentAggregate
    [timespan]$TimeSpent
    [uri]$Link
    [Worklog[]]$Worklogs
    Issue([pscustomobject]$jiraIssueObject) {
        $this.Asignee = [Person]::new($jiraIssueObject.assignee)
        $this.Reporter = [Person]::new($jiraIssueObject.Reporter)
        $this.Status = $jiraIssueObject.Status
        $this.TimeSpentAggregate = [timespan]::FromSeconds($jiraIssueObject.aggregatetimespent)
        $this.TimeSpent = [timespan]::FromSeconds($jiraIssueObject.timespent)
        $this.Creator = $jiraIssueObject.Creator
        $this.Key = $jiraIssueObject.Key
        $this.Name = $jiraIssueObject.Summary
        $this.Link = [uri]::new($jiraIssueObject.HttpUrl)
        $maxWorkLogs = $jiraIssueObject.worklog.Total
        $this.Worklogs = Get-JiraIssueWorklog -Issue $this.Key | Select-Object -First $maxWorkLogs | ForEach-Object -Begin {
            $i = 0; $null = $i
        } -Process {
            Write-Progress -Activity 'Parsing worklogs...' -Status $_.Created -PercentComplete ($i / $maxWorkLogs * 100) @barParams
            $i++
            [Worklog]::new($_, $this) 
        } -End {
            Write-Progress -Activity 'Parsing worklogs...' -Status 'Done' @barParams -Completed
        }
    }
    [Worklog[]] FilterLogsByDate([datetime]$startDate, [datetime]$endDate, [string[]]$user = $null) {
        if ($user.Length -gt 1) {
            $f = $this.Worklogs | Where-Object { $_.Started -ge $startDate -and $_.started -lt $endDate -and ($_.Author.Name -in $user -or $_.Author.ID -in $user) }
        } elseif (-not [string]::IsNullOrWhiteSpace($user[0])) {
            $f = $this.Worklogs | Where-Object { $_.Started -ge $startDate -and $_.started -lt $endDate -and $_.Author.Equals($user[0]) }
        } else {
            $f = $this.Worklogs | Where-Object { $_.Started -ge $startDate -and $_.started -lt $endDate }
        }
        return $f | Sort-Object Started
    }
    [SummedWorklogs] FilterLogsByDateSummed([datetime]$startDate, [datetime]$endDate, [string]$user = $null) {
        return [SummedWorklogs]::new($this.FilterLogsByDate([datetime]$startDate, [datetime]$endDate, $user)) 
    }
    [string]ToString() {
        return $this.FullName
    }
    [string]Crop([int]$Length) {
        if ($this.FullName.Length -le $Length - 1) {
            return $this.FullName
        }
        return $this.FullName.Substring(0, $Length - 2) + '~ '
    }
}