function Get-AvJiraIssue_Query {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Query,
        [Parameter()]
        [string[]]
        $User,
        [Parameter()]
        [string[]]
        $Status
    )
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
        Write-WrappedProgress -Activity 'Parsing issues...' -Status $_.Key -current $counter -Total $total 
        $counter++
        [Issue]::new($_)
    } 
}