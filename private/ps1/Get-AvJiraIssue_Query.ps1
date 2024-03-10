function Get-AvJiraIssue_Query {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Query,
        [Parameter()]
        [string[]]
        $Assignee,
        [Parameter()]
        [string[]]
        $Status
    )
    $addParts = @($query)
    if ($Assignee) {
        $quoted = $Assignee | ForEach-Object { "'$_'" }
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
    Write-Log $final_query
    Write-WrappedProgress -Activity 'Getting issues...' -Status "Fetching query: $final_query"
    $rawIssues = Get-JiraIssue -Query $final_query
    $total = $rawIssues.Count
    $counter = 0
    Get-JiraIssue -Query $final_query | ForEach-Object { 
        $counter++
        Write-WrappedProgress -Activity 'Getting issues...' -Status $_.Key -current $counter -Total $total 
        [Issue]::new($_)
    } 
}