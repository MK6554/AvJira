
function Get-AvJiraWorklog {
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
    Test-AvJiraSession
    if (-not $User -and $periodMode) {
        Write-Verbose "No username specified. Defaulting to credential's name."
        $User = (Get-JiraSession).UserName
    }

    if ($issueMode) {
        $foundIssue = Get-AvJiraIssue -Issue $Issue
        if (-not $foundIssue) {
            $msg = if (@($issue).Count -eq 1) { "Issue $issue could not be found" } else { "Issues $issue could not be found" }
            Write-Error $msg -ErrorAction Stop
        }
        $foundIssue | ForEach-Object Worklogs | Sort-Object Started
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

        $foundIssue = Get-AvJiraIssue -Query $query
        if (-not $foundIssue) {
            Write-Error "Query $query yielded no results" -ErrorAction Stop
        }
        $foundIssue.FilterLogsByDate($startDate, $endDate, $user) | Sort-Object Started
    }
}
