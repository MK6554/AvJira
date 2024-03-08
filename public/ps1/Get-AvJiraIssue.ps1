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
    Write-Progress -Activity 'Fetching issues...' -Status 'Contacting server...' @barParams
    if ($PSCmdlet.ParameterSetName -eq 'KEY') {
        $rawIssues = Get-JiraIssue $issue
        $total = $rawIssues.Count
        $counter = 0
        $rawIssues | ForEach-Object {
            Write-Progress -Activity 'Parsing issues...' -Status $_.Key -PercentComplete ($counter / $total * 100) @barParams
            $counter++
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
        $rawIssues = Get-JiraIssue -Query $final_query
        $total = $rawIssues.Count
        $counter = 0
        Get-JiraIssue -Query $final_query | ForEach-Object { 
            Write-Progress -Activity 'Parsing issues...' -Status $_.Key -PercentComplete ($counter / $total * 100) @barParams
            $counter++
            [Issue]::new($_)
        } 
        Write-Progress -Activity 'Parsing issues...' -Status 'Done' -Completed @barParams
    }
}

$barParams = @{
    ID = 420
}