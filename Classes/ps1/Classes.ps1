enum Period {
    ThisMonth = 0
    LastMonth = 1
    ThisWeek = 2
    LastWeek = 3
    Today = 4
    Yesterday = 5
    ThisYear = 6
    LastYear = 7
    AllTime = 8
}

class Issue {
    hidden [pscustomobject] $sourceObject
    [string]$Key
    [string]$Summary
    [Person]$Reporter
    [Person]$Creator
    [Person]$Asignee
    [string[]]$Status
    [timespan]$TimeSpentAggregate
    [timespan]$TimeSpent
    [uri]$Link
    hidden [int]$WorklogCount
    hidden [int]$CommentCount

    hidden static [bool] $MembersAdded = $false

    hidden static [void]  AddMembers() {
        if ([Issue]::MembersAdded) { return }
        $MemberDefinitions = @(
            @{
                MemberName = 'Name'
                MemberType = 'AliasProperty'
                Value      = 'Summary'
            }, @{
                MemberName = 'FullName'
                MemberType = 'ScriptProperty'
                Value      = { $this.Key + ' ' + $this.Summary }
            }, @{
                MemberName = 'TimeSpentSeconds'
                MemberType = 'ScriptProperty'
                Value      = { $this.TimeSpent.TotalSeconds }
            }, @{
                MemberName = 'TimeSpentAggregateSeconds'
                MemberType = 'ScriptProperty'
                Value      = { $this.TimeSpentAggregate.TotalSeconds }
            })
        $TypeName = [Issue].Name
        foreach ($Definition in $MemberDefinitions) {
            Update-TypeData -TypeName $TypeName @Definition
        }
        [Issue]::MembersAdded = $true
    }

    Issue([pscustomobject]$jiraIssueObject) {
        $this.sourceObject = $jiraIssueObject

        $this.Key = $jiraIssueObject.Key
        $this.Summary = $jiraIssueObject.Summary

        $this.Reporter = [Person]::new($jiraIssueObject.Reporter)
        $this.Creator = [Person]::new($jiraIssueObject.Creator)
        $this.Asignee = [Person]::new($jiraIssueObject.Assignee)

        $this.Status = [string[]]$jiraIssueObject.Status

        $this.TimeSpentAggregate = [timespan]::FromSeconds($jiraIssueObject.aggregatetimespent)
        $this.TimeSpent = [timespan]::FromSeconds($jiraIssueObject.timespent)

        $this.Link = [uri]::new($jiraIssueObject.HttpUrl)
        $this.WorklogCount = if ($jiraIssueObject.worklog -is [object[]]) { $jiraIssueObject.worklog.count }else { $jiraIssueObject.worklog.Total }
        $this.CommentCount = if ($jiraIssueObject.comment -is [object[]]) { $jiraIssueObject.comment.count }else { $jiraIssueObject.comment.Total }

        [Issue]::AddMembers()

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

    [void]GetWorklogs() {
        Write-Error 'To get worklogs from issue, use cmdlet Get-AvJiraWorklog'
    }
}

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
class SummedWorklogs {
    hidden [Worklog[]]$Worklogs
    [timespan]$TimeSpentTotal
    [int]$WorklogCount
    [string[]]$Issue

    hidden static [bool] $MembersAdded = $false

    hidden static [void]  AddMembers() {
        if ([Issue]::MembersAdded) { return }
        $MemberDefinitions = @{
            MemberName = 'WorklogCount'
            MemberType = 'ScriptProperty'
            Value      = { $this.Worklogs.Count }
        }
        $TypeName = [SummedWorklogs].Name
        foreach ($Definition in $MemberDefinitions) {
            Update-TypeData -TypeName $TypeName @Definition
        }
        [SummedWorklogs]::MembersAdded = $true
    }

    SummedWorklogs([Worklog[]]$logs) {
        $this.Worklogs = $logs
        $this.TimeSpentTotal = $logs | Measure-Object -Sum -Property TimeSpentSeconds | ForEach-Object { [timespan]::FromSeconds([int]($_.Sum)) }
        $this.Issue = $logs | ForEach-Object { $_.Issue.FullName } | Select-Object -Unique
        [SummedWorklogs]::AddMembers()
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

    Worklog([pscustomobject]$jiraLogObject, [Issue]$issue) {
        $this.Issue = $issue
        $this.Author = [Person]::new($jiraLogObject.author)
        $this.Comment = $jiraLogObject.Comment
        $this.Started = $jiraLogObject.Started
        $this.Created = $jiraLogObject.Created
        $this.TimeSpent = [timespan]::FromSeconds($jiraLogObject.timespentseconds)
    }
}

class JiraDateTimeConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [datetime]) {
            return $inputData
        } elseif ($inputData -is [int] -and $inputData -le 0) {
            return [datetime]::Now.AddDays($inputData)
        } elseif ($inputData -is [string]) {
            [string[]]$formats = @(
                'yyyyMMdd', 
                'MMdd', 
                'dd',
                'yyyyMMddhhmm', 
                'MMddhhmm', 
                'ddhhmm',
                'yyyyMMdd', 
                'MMdd', 
                'dd'
            )
            [datetime]$result = 0
            $inputStr = $inputData -replace '[\D]', ''
            if ([datetime]::TryParseExact($inputStr, $formats, $null, [System.Globalization.DateTimeStyles]::None, [ref]$result)) {
                if ($result.TimeOfDay -eq [timespan]::Zero) {
                    $result = $result.Add([datetime]::now.TimeOfDay)
                }
                return $result
            }
        }
        throw [System.ArgumentException]::new('Cannot convert to datetime')
    }
}
class JiraTimeSpanConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [timespan]) {
            return $inputData
        } elseif ($inputData -is [int]) {
            return [timespan]::FromMinutes($inputData)
        } elseif ($inputData -is [string]) {
            [string[]]$formats = @(
                'hh\:mm\', 
                'hhmm', 
                'mm', 
                'hh\hmm\m', 
                'hh\hm\m', 
                'h\hmm\m', 
                'h\hm\m', 
                'hh\h',
                'h\h',
                'mm\m'
                'm\m'
            )
            [timespan]$result = 0
            $inputStr = $inputData -replace '[^hHmM\d:]', ''
            if ([timespan]::TryParseExact($inputStr, $formats, $null, [ref]$result)) {
                return $result
            }
        }
        throw [System.ArgumentException]::new('Cannot convert to timespan')
    }
}