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

class IssueBase {
    hidden [pscustomobject] $sourceObject
    [string]$Key
    [string]$Summary
    [string[]]$Status
    IssueBase([pscustomobject]$jiraIssueObject) {
        $this.sourceObject = $jiraIssueObject
        $this.Key = $jiraIssueObject.Key
        $this.Summary = $jiraIssueObject.Summary
        $this.Status = [string[]]$jiraIssueObject.Status
    }
    # IssueBase([string]$key, [string]$summary, [string[]]$status) {
    #     $this.sourceObject = $null
    #     $this.Key = $key
    #     $this.Summary = $summary
    #     $this.Status = $status
    # }
    static [IssueBase] FromSubtaskNode([pscustomobject]$node) {
        $pseudoIssueNode = [pscustomobject]@{
            Key     = $node.Key
            Summary = $node.fields.summary
            Status  = $node.fields.status
        }
        return [IssueBase]::new($pseudoIssueNode)
    }
}

class Issue : IssueBase {
    # hidden [pscustomobject] $sourceObject
    # hidden [Issue]$Issue
    # [string]$Key
    # [string]$Summary
    # [string[]]$Status
    hidden [Issue]$Issue
    [Person]$Reporter
    [Person]$Creator
    [Person]$Asignee
    [datetime]$Created
    [datetime]$Updated
    [timespan]$TimeSpentAggregate
    [timespan]$TimeSpent
    [IssueBase[]]$Subtasks
    [IssueBase]$Parent
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

    Issue([pscustomobject]$jiraIssueObject):base($jiraIssueObject) {
        $this.Reporter = [Person]::new($jiraIssueObject.Reporter)
        $this.Creator = [Person]::new($jiraIssueObject.Creator)
        $this.Asignee = [Person]::new($jiraIssueObject.Assignee)

        $this.Created = $jiraIssueObject.Created
        $this.Updated = $jiraIssueObject.Updated

        $this.TimeSpentAggregate = [timespan]::FromSeconds($jiraIssueObject.aggregatetimespent)
        $this.TimeSpent = [timespan]::FromSeconds($jiraIssueObject.timespent)

        $this.Link = [uri]::new($jiraIssueObject.HttpUrl)
        $this.WorklogCount = if ($jiraIssueObject.worklog -is [object[]]) { $jiraIssueObject.worklog.count }else { $jiraIssueObject.worklog.Total }
        $this.CommentCount = if ($jiraIssueObject.comment -is [object[]]) { $jiraIssueObject.comment.count }else { $jiraIssueObject.comment.Total }
        $this.Subtasks = $jiraIssueObject.Subtasks | ForEach-Object { [IssueBase]::FromSubtaskNode($_      ) }
        $this.Parent = if ($jiraIssueObject.parent) { [IssueBase]::FromSubtaskNode($jiraIssueObject.parent) }else { $null }
        $this.Issue = $this
        [Issue]::AddMembers()

    }
    [bool]Equals([object]$other) {
        if ($null -eq $other) {
            return $false
        }
        if ($other -is [Issue]) {
            return $this.Key -eq $other.Key
        }
        return $false
    }

    [int]GetHashcode() {
        return $this.Key.GetHashCode()
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
    [string]$Header
    [timespan]$TimeSpentTotal
    [int]$WorklogCount
    [string[]]$Issue

    hidden static [bool] $MembersAdded = $false

    hidden static [void]  AddMembers() {
        if ([SummedWorklogs]::MembersAdded) { return }
        $MemberDefinitions = @(
            @{
                MemberName = 'WorklogCount'
                MemberType = 'ScriptProperty'
                Value      = { $this.Worklogs.Count }
            }, @{ 
                MemberName = 'TotalTime'
                MemberType = 'AliasProperty'
                Value      = 'TimeSpentTotal'
            }, @{ 
                MemberName = 'IssueCount'
                MemberType = 'ScriptProperty'
                Value      = { $this.Issue.Count }
            }
        )
        $TypeName = [SummedWorklogs].Name
        foreach ($Definition in $MemberDefinitions) {
            Update-TypeData -TypeName $TypeName @Definition
        }
        [SummedWorklogs]::MembersAdded = $true
    }

    SummedWorklogs([Worklog[]]$logs, [string]$Header) {
        $this.Header = $Header
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
    [string]$Comment
    [Person]$Author

    hidden static [bool] $MembersAdded = $false

    hidden static [void]  AddMembers() {
        if ([Worklog]::MembersAdded) { return }
        $MemberDefinitions = @(@{
                MemberName = 'TimeSpentSeconds'
                MemberType = 'ScriptProperty'
                Value      = { $this.TimeSpent.TotalSeconds }
            }, @{
                MemberName = 'Month'
                MemberType = 'ScriptProperty'
                Value      = { $this.Started.Month }
            }, @{
                MemberName = 'Year'
                MemberType = 'ScriptProperty'
                Value      = { $this.Started.Year }
            }, @{
                MemberName = 'Day'
                MemberType = 'ScriptProperty'
                Value      = { $this.Started.Day }
            }
        )
        $TypeName = [Worklog].Name
        foreach ($Definition in $MemberDefinitions) {
            Update-TypeData -TypeName $TypeName @Definition
        }
        [Worklog]::MembersAdded = $true
    }

    Worklog([pscustomobject]$jiraLogObject, [Issue]$issue) {
        $this.Issue = $issue
        $this.Author = [Person]::new($jiraLogObject.author)
        $this.Comment = $jiraLogObject.Comment
        $this.Started = $jiraLogObject.Started
        $this.Created = $jiraLogObject.Created
        $this.TimeSpent = [timespan]::FromSeconds($jiraLogObject.timespentseconds)
        [Worklog]::AddMembers()
    }
}

class JiraDateTimeConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [datetime]) {
            return $inputData
        }
        $inputData = $inputData | Out-String
        if ($inputData -match '-\d+') {
            try {
                [int]$dateInt = [int]::parse($inputData)
                if ($dateInt -lt 0) {
                    return [datetime]::now.AddDays($dateInt)
                }
            } catch [System.FormatException], [System.OverflowException] {
            }
        }
        [string[]]$formats = @(
            'yyyyMMdd', 
            'MMdd', 
            'dd',
            'yyyyMMddTHHmm', 
            'MMddTHHmm', 
            'ddTHHmm'
        )
        [datetime]$result = 0
        $inputStr = $inputData -replace '[^0-9Tt]', ''
        $inputStr = $inputStr.ToUpper()
        if ([datetime]::TryParseExact($inputStr, $formats, $null, [System.Globalization.DateTimeStyles]::None, [ref]$result)) {
            if ($result.TimeOfDay -eq [timespan]::Zero) {
                $result = $result.Add([datetime]::now.TimeOfDay)
            }
            return $result
        }
        throw [System.ArgumentException]::new('Cannot convert to datetime')
    }
    [datetime] Transform([object]$inputData) {
        return $this.Transform($null, $inputData)
    }

    [string] HelpMessage() {
        return @('Default format is [year] [month] [day]. The time part is current time.'
            "You can skip the first two - missing elements are taken from today's date"
            'Any whitespace inside the string is removed.'
            "You can specify the time part manually - the format is [hours] [minutes]. You have to separate date and time with 'T'."
            'Example: 2006 10 13 T 13 37'
            'You can also provide a negative number whic tells how many days should be subtracted from today.'
            'So, -1 gives yesterday, -2 gives ereyesterday.') -join "`n"
    }
}
class JiraTimeSpanConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [timespan]) {
            return $inputData
        } elseif ($inputData -is [int]) {
            return [timespan]::FromMinutes($inputData)
        } 
        $inputData = $inputData | Out-String
        [string[]]$formats = @(
            'hh\:mm\', 
            'hhmm', 
            'mm', 
            'hh\hmm\m', 
            'hh\hm\m', 
            'hh\h',
            'mm\m'
        )
        [timespan]$result = 0
        $inputStr = $inputData -replace '[^hHmM\d:]', '' # remove everything that is not a number or h/m
        $inputStr = $inputStr -replace '(?<!\d)\d(?!\d)', '0$0' # find all digits, which do NOT have a leading digit and do NOT have a following digit
        # in short - find all single digits - replace them by adding a leading zero
        $inputStr = $inputStr.ToLower()
        if ([timespan]::TryParseExact($inputStr, $formats, $null, [ref]$result)) {
            return $result
        }
        throw [System.ArgumentException]::new('Cannot convert to timespan')
    }
    [timespan] Transform([object]$inputData) {
        return $this.Transform($null, $inputData)
    }
    [string] HelpMessage() {
        return @('Default format is [hours] [minutes]. With optional colon between them.' 
            'Any whitespace inside the string is removed.'
            'If you provide only one number it is treated as minutes.'
            "You can also add 'h' or 'm' after a number to denote its unit (like in Jira). This allows you to provide just the hours.") -join "`n"
        
    }
}