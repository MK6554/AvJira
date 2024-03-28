function Get-AvJiraIssue_Issue {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object[]]
        $Issue,
        [Parameter()]
        [switch]
        $NoSubtasks
    )
    $issuesToReturn = [System.Collections.Hashtable]::new([System.StringComparer]::InvariantCultureIgnoreCase)
    foreach ($issueInput in $Issue) {
        if ($issueInput -is [Issue]) {
            $null = $issuesToReturn.add($issueInput.ID, $issueInput)
            if (-not $NoSubtasks.IsPresent) {
                $null = $idsToFetch.AddRange($issueInput.Subtasks.ID)
            }
        } elseif ($issueInput -is [IssueBase]) {
            $null = $issuesToReturn.Add($issueInput.ID, $null)
        } elseif ($issueInput -is [string]) {
            $null = $issuesToReturn.Add($issueInput, $null)
        }
    }
    # return issue instances without processing
    do {
        $toFetch = $issuesToReturn.GetEnumerator() | Where-Object Value -EQ $null | Select-Object -ExpandProperty Key
        Write-WrappedProgress -Activity 'Getting issues...' -Status "Fetching issues: $toFetch"
        Get-JiraIssue $toFetch | 
            ForEach-Object {
                $node = [Issue]::new($_) 
                $issuesToReturn[$node.Key] = $node
            }
        $allSubtasks = if ($NoSubtasks.IsPresent) { @() }else { @($issuesToReturn.Values.Subtasks.Key) }
        foreach ($subtask in $allSubtasks) {
            if (-not $issuesToReturn.ContainsKey($subtask)) {
                $issuesToReturn[$subtask] = $null
            }
        }
        $hasAllInstances = @($issuesToReturn.GetEnumerator() | Where-Object Value -EQ $null).Count -eq 0
    } until ($hasAllInstances )

    $listToReturn = @($issuesToReturn.Values)
    if ($listToReturn) {
        $count = $listToReturn.Count
        
        for ($i = 0; $i -lt $count; $i++) {
            $item = $listToReturn[$i]
            Write-WrappedProgress -Activity 'Getting issues...' -Status $item.Key -current ($i + 1) -Total $count
            $item
        }
    }
} 
function Get-Node {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Issue]
        $IssueInstance,
        [Parameter()]
        [string]
        $Key,
        [Parameter()]
        [psobject]
        $RawIssue
    )
    if ($null -ne $IssueInstance) {
        $key = $IssueInstance.Key
    }
    [pscustomobject]@{
        Key      = $Key.ToUpper()
        Instance = $IssueInstance
    }
}