function Get-AvJiraIssue {
    <#
.SYNOPSIS
    Returns issues matching the given criteria: ID or Jira Query.
.DESCRIPTION
    Returns issues matching the given criteria: ID or Jira Query.
.EXAMPLE
    Get-AvJiraIssue [-Issue]  AAA-BBB, CCC-DDD
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
    Test-AvJiraSession
    if ($PSCmdlet.ParameterSetName -eq 'KEY') {
        Write-Progress -Activity 'Fetching issues...' @$barParams
        $rawIssues = Get-JiraIssue $issue
        $total = $rawIssues.Count
        $counter = 0
        Get-JiraIssue $issue | ForEach-Object {
            Write-Progress -Activity 'Parsing issues...' -Status $_.Key -Id 420 -PercentComplete ($counter / $total * 100) @$barParams
            [Issue]::new($_) } 
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
            Write-Progress -Activity 'Parsing issues...' -Status $_.Key @$barParams
            [Issue]::new($_)
        } 
        Write-Progress -Activity 'Parsing issues...' -Status 'Done' -Completed @$barParams
    }
}

$barParams = @{
    ID = 420
}