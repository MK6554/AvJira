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
        [Parameter(ParameterSetName = 'ISSUE', ValueFromPipelineByPropertyName)]
        [object[]]
        $Issue
    )
    begin {
        Test-AvJiraSession
        $local:outside_checkPerformed = $true # will skip session test for any subcommands
        $null = $local:outside_checkPerformed # to silence warnings about unused variable

    }
    process {
        $issueMode = $PSCmdlet.ParameterSetName -eq 'ISSUE'
        $periodMode = $PSCmdlet.ParameterSetName -eq 'PERIOD'

        if (-not $User -and $periodMode) {
            Write-Verbose "No username specified. Defaulting to credential's name."
            $User = (Get-JiraSession).UserName
        }

        if ($issueMode) {
        
            Get-AvJiraIssue -Issue $Issue | Get-AvJiraWorklog_Impl
        
        } else {
            #periodMode
            $query, $startDate, $endDate = Get-AvJiraQuery $period

            $user = $user | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $queryParts = @($query)
            if (@($user).Count -eq 1) {

                $queryParts += @("worklogAuthor = '$user'")

            } elseif (@($user).Count -gt 1) {

                $user = $user | ForEach-Object { "'$_'" }
                $joined = '(' + ($user -join ', ') + ')'
                $queryParts += @("worklogAuthor in $joined")
            }
            $queryParts = $queryParts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $query = $queryParts -join ' AND '

            $worklogs = Get-AvJiraIssue -Query $query | Get-AvJiraWorklog_Impl
            $worklogs
        }
    }
}
