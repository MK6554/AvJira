class Person {
    [string]$Name
    [string]$ID
    Person([string]$name, [string]$id) {
        $this.Init($name, $id)
    }
    Person([pscustomobject]$jiraPersonObject) {
        $this.Init($jiraPersonObject.displayname, $jiraPersonObject.name)
    }
    hidden Init([string]$name, [string]$id) {
        $this.ID = $id
        $this.Name = $Name
    }
    [bool]Equals($other) {
        if ($other -is [Person]) {
            return $other.ID -eq $this.ID
        } elseif ($other -is [string]) {
            return $this.ID -eq $other -or $this.Name -eq $other
        }
        return $false
    }
    [string]ToString() {
        return "$($this.Name) ($($this.ID))"
    }
}

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
        $this.Worklogs = Get-JiraIssueWorklog -Issue $this.Key | Select-Object -First $maxWorkLogs | ForEach-Object { $i = 0 } {
            Write-Progress -Activity 'Parsing worklogs...' -Status $_.Created -Id 2137 -ParentId 420 -PercentComplete ($i / $maxWorkLogs * 100)
            $i++
            [Worklog]::new($_, $this) }
        Write-Progress -Activity 'Parsing worklogs...' -Status 'Done' -Id 2137 -Completed
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

class Worklog {
    [Issue]$Issue
    [datetime]$Started
    [datetime]$Created
    [timespan]$TimeSpent
    [int]$TimeSpentSeconds
    [string]$Comment
    [Person]$Author
    Worklog([pscustomobject]$jiraLogObject, [Issue]$parent) {
        $this.Issue = $parent
        $this.Author = [Person]::new($jiraLogObject.author)
        $this.Comment = $jiraLogObject.Comment
        $this.Started = $jiraLogObject.Started
        $this.Created = $jiraLogObject.Created
        $this.TimeSpent = [timespan]::FromSeconds($jiraLogObject.timespentseconds)
    }
}

enum Period {
    ThisMonth = 1
    LastMonth = 2
    ThisWeek = 3
    LastWeek = 4
    Today = 5
    Yesterday = 5
    ThisYear = 6
    LastYear = 7
}