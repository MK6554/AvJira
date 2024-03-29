function Get-AvJiraIssue_Issue {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object[]]
        $Issue
    )
    $issueIssues = $issue | Where-Object { $_ -is [issue] } # if any issue instances were passed, relay them
    if($issueIssues){
        $issueIssues
    }

    $stringIssues = $issue | Where-Object { $_ -is [string] }

    if ($stringIssues) {

        Write-WrappedProgress -Activity 'Getting issues...' -Status "Fetching issues: $stringIssues"
        $rawIssues = Get-JiraIssue $stringIssues
        $count = $stringIssues.Count
        
        for ($i = 0; $i -lt $count; $i++) {
            $item = $rawIssues[$i]
            Write-WrappedProgress -Activity 'Getting issues...' -Status $item.Key -current ($i + 1) -Total $count
            [Issue]::new($item)
        }
    }
}