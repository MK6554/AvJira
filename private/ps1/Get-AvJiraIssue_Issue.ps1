function Get-AvJiraIssue_Issue {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object[]]
        $Issue
    )
    $issue | Where-Object { $_ -is [issue] } # if any issue instances were passed, relay them

    $stringIssues = $issue | Where-Object { $_ -is [string] }

    $rawIssues = Get-JiraIssue $stringIssues
    $count = $stringIssues.Count

    for ($i = 0; $i -lt $count; $i++) {
        $item = $rawIssues[$i]
        Write-WrappedProgress -Activity 'Parsing issues...' -Status $item.Key -current $i -Total $count
        [Issue]::new($item)
    }
}