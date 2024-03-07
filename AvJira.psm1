function Get-Issue {
    <#
.SYNOPSIS
    Returns issues matching the given criteria: ID or Jira Query.
.DESCRIPTION
    Returns issues matching the given criteria: ID or Jira Query.
.EXAMPLE
    Get-Issue [-Issue]  AAA-BBB, CCC-DDD
    returns specified issues (which include worklogs)
.PARAMETER Issue
    ID of issue. Can specify multiple, separated with a comma
.PARAMETER Query
    Jira Query language string used to filter issues. More information: https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/
#>
    [CmdletBinding(DefaultParameterSetName = 'KEY')]
    [OutputType([Issue])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'KEY')]
        [string[]]
        $Issue,
        [Parameter(ParameterSetName = 'QUERY')]
        [string]
        $Query,
        [Parameter(ParameterSetName = 'QUERY')]
        [string[]]
        $User,
        [Parameter(ParameterSetName = 'QUERY')]
        [string[]]
        $Status
    )
    Test-Session
    if ($PSCmdlet.ParameterSetName -eq 'KEY') {
        Get-JiraIssue $issue | ForEach-Object { [Issue]::new($_) } 
    } else {
        $addParts = @($query)
        if ($user) {
            $quoted = $user | ForEach-Object { "'$_'" }
            $commaed = $quoted -join ', '
            $addParts += "assignee in ($commaed)"
        }
        if ($Status) {
            $quoted = $Status | ForEach-Object { "'$_'" }
            $commaed = $quoted -join ', '
            $addParts += "Status in ($commaed)"
        }
        $parts = $addParts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $final_query = $parts -join ' AND '
        Write-Verbose $final_query
        Get-JiraIssue -Query $final_query | ForEach-Object { 
            Write-Progress -Activity 'Parsing projects...' -Status $_.Key -Id 420
            [Issue]::new($_)
        } 
        Write-Progress -Activity 'Parsing projects...' -Status 'Done' -Id 1 -Completed
    }
}

function Get-Worklog {
    <#
    .SYNOPSIS
        Returns worklogs from the given period or issue
    .DESCRIPTION
        Returns worklogs which are either from the given period or from specified issues.
    .PARAMETER Period
        Period of time from which logs should be fetched
    .PARAMETER User
        Optional user name to limit worklogs to.
    .PARAMETER Issue
        Isue from which the logs will be fetched. Cannot be used with -Period.
    .EXAMPLE
        Get-AvJiraWorkLog [-Period] LastMonth
        returns logs from last month for the logged in user
    #>
    [CmdletBinding(DefaultParameterSetName = 'PERIOD')]
    param (
        [Parameter(ParameterSetName = 'PERIOD', Position = 0)]
        [Period]
        $Period = [period]::ThisMonth,
        [Parameter()]
        [string[]]
        $User,
        [Parameter(ParameterSetName = 'ISSUE')]
        [string[]]
        $Issue
    )
    $issueMode = $PSCmdlet.ParameterSetName -eq 'ISSUE'
    $periodMode = $PSCmdlet.ParameterSetName -eq 'PERIOD'
    Test-Session
    if (-not $User -and $periodMode) {
        Write-Verbose "No username specified. Defaulting to credential's name."
        $User = (Get-JiraSession).UserName
    }

    if ($issueMode) {
        $foundIssue = Get-Issue -Issue $Issue
        if (-not $foundIssue) {
            $msg = if (@($issue).Count -eq 1) { "Issue $issue could not be found" } else { "Issues $issue could not be found" }
            Write-Error $msg -ErrorAction Stop
        }
        $foundIssue | Sort-Object Started
    } else {
        #periodMode
        $query, $startDate, $endDate = GetQuery $period

        $user = $user | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if (@($user).Count -eq 1) {
            $query += " AND worklogAuthor = '$user'"
        } elseif (@($user).Count -gt 1) {
            $user = $user | ForEach-Object { "'$_'" }
            $joined = '(' + ($user -join ', ') + ')'
            $query += " AND  worklogAuthor in $joined"
        }

        $foundIssue = Get-Issue -Query $query
        if (-not $foundIssue) {
            Write-Error "Query $query yielded no results" -ErrorAction Stop
        }
        $foundIssue.FilterLogsByDate($startDate, $endDate, $user) | Sort-Object Started
    }
}

function Get-WorklogSum {
    <#
    .SYNOPSIS
        Sums given logs up.
    .DESCRIPTION
        Return total time spent from given logs. This cmdlet should be used in pipeline (with the | operator)
    .EXAMPLE
        get-avjiraworklog | avjiralogsum
    #>
    
    [CmdletBinding()]
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
Set-Alias -Name logsum -Value Get-WorklogSum

function Add-Worklog {
    [CmdletBinding()]
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
        $Time
    )
    Test-Session
    while (-not $issue) {
        $Issue = Read-Host 'Enter issue ID'
        if (-not $Issue) { Write-Host 'Issue cannot be empty' }
    }
    if (-not $Comment) {
        $Comment = Read-Host 'Enter work log comment'
    } 
    if (-not $Time) {
        while ($true) {
            $temp = Read-Host 'Enter time spent'
            try {
                $Time = [JiraTimeSpanConverterAttribute]::new().Transform($null, $temp)
                break
            } catch [System.ArgumentException] {
                Write-Host "$temp was not invalid time format. Try again (hh:mm:ss or hhmmss)."
            }
        }
    } 
    if (-not $Date) {
        $now = [datetime]::now
        while ($true) {
            $temp = Read-Host "Enter date of work (leave empty to use current date: $now))"
            if ($temp -notmatch '[\d-:]+') {
                $Date = $now
                break
            } else {
                try {
                    $Date = [JiraDateTimeConverterAttribute]::new().Transform($null, $temp)
                    break
                } catch [System.ArgumentException] {
                    Write-Host "$temp was not a valid date. Try again (yyyy-mm-dd)."
                }
            }
        }
    }
    $log = @{
        Comment     = $Comment
        Issue       = $Issue
        TimeSpent   = $Time
        DateStarted = $date.ToString('yyyy-MM-dd')
    }
    Write-Host 'Log to add:'
    ([pscustomobject]$log) | Out-String
    Read-Host 'Press ENTER to add or CTRL-Z to cancel'
    Add-JiraIssueWorklog @log  
}



function Set-Credentials {
    [CmdletBinding()]
    param (    )
    $Username = Read-Host 'Enter username'
    $ApiKey = Read-Host 'Enter password or API key' -AsSecureString
    $creds = New-Object System.Management.Automation.PSCredential($username, $ApiKey)
    $apikey = $creds.GetNetworkCredential().Password
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $CertificateName
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -DnsName $CertificateName -CertStoreLocation 'Cert:\CurrentUser\My' -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement -Type DocumentEncryptionCert -Verbose
    }
    if (Test-Path $EncryptedApiPath) {
        Remove-Item $EncryptedApiPath
    }
    $msg = "$username$Separator$apikey"
    $msg | Protect-CmsMessage -To "cn=$CertificateName" -OutFile $EncryptedApiPath -Verbose
}

function Test-Session {
    if (-not (Get-JiraConfigServer)) {
        Write-Warning 'Jira server is not configured!'
        $address = Read-Host 'Enter Jira server address (https://jira.[company].com)'
        Set-JiraConfigServer $address
    }
    if (-not (Get-JiraSession)) {
        Write-Verbose 'No session active. Creating...'
        $key = LoadApiKey
        if (-not $key) {
            $cred = Get-Credential -Message 'Saved credential not found. Provide username and password for this session. You can create saved credential with Set-(AvJira)Credentials'
        } else {
            $username, $api = $key.split($Separator, [System.StringSplitOptions]::RemoveEmptyEntries)
            $password = ConvertTo-SecureString $api -AsPlainText -Force -ErrorAction Stop
            $cred = New-Object System.Management.Automation.PSCredential ($username, $password)
        }
        $null = New-JiraSession -Credential $cred
    }
}

$CertificateName = 'AvJiraEncrytingCertificate'
$EncryptedApiFileName = "JiraApi$($env:USERNAME).cms"
$Separator = ';;;;____;;;;'

function LoadApiKey {
    $versionFolder = Join-Path $PSScriptRoot '..'
    $key = Get-ChildItem $versionFolder -Recurse -Filter $EncryptedApiFileName -Depth 1 | Sort-Object LastWriteTime | Select-Object -First 1
    if (-not $key) { return }
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $CertificateName
    if (-not $cert) { return }
    Unprotect-CmsMessage -Path $key.FullName
}

function GetQuery {
    param (
        [Period]
        $Period
    )
    $periodStr = if ($Period -eq 'Today') { 'ThisDay' }elseif ($Period -eq 'Yesterday') { 'LastDay' }else { $period.TOstring() }
    $methodStem = $periodStr.Substring(4)
    $arg = if ($periodStr -like 'This*') { 0 }else { -1 }
    $startDateQuery = 'startOf' + $methodStem + "($arg)"
    $endDateQuery = 'endOf' + $methodStem + "($arg)"
    $query = "worklogDate >= $startDateQuery AND worklogDate < $endDateQuery"
    
    $thisDayStart = [datetime]::Today
    $thisWeekStart = [datetime]::today.adddays( - [int]$thisDayStart.DayOfWeek + 1) # jira starts week on Sunday (xDDDD); +1 because dayofweek enum starts at 1 so it would subtract to saturday
    $thisMonthStart = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0
    $thisyearStart = Get-Date -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
    $startDatetime, $endDateTime = if ($methodStem -eq 'Month') {
        $thisMonthStart.AddMonths($arg)
        $thisMonthStart.AddMonths($arg + 1).AddSeconds(-1)
    } elseif ($methodStem -eq 'Week') {
        $thisWeekStart.AddDays($arg * 7)
        $thisWeekStart.AddDays(($arg + 1) * 7).AddSeconds(-1)
    } elseif ($methodStem -eq 'Year') {
        $thisyearStart.AddYears($arg)
        $thisyearStart.AddYears($arg + 1).AddSeconds(-1)
    } else {
        #day
        $thisDayStart.AddDays($arg)
        $thisDayStart.AddDays($arg + 1).AddSeconds(-1)
    }

    $query, $startDateTime, $endDateTime
}
