function Find-WorklogGroupingObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]
        $Logs,
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [object[]]
        $GroupingValue
    )
    $possibleGroupings = @('Year', 'Month', 'Day', 'Issue')
    $groupHeaders = [System.Collections.ArrayList]::new()
    $groupValues = [System.Collections.ArrayList]::new()
    foreach ($possibleGrouping in $possibleGroupings) {
        $values = $Logs.$possibleGrouping | Select-Object -Unique
        $isOne = $values.count -eq 1
        $isMatch = if ($isOne -and $GroupingValue) { $GroupingValue -contains $values[0] } else { $true }
        if ($isOne -and $isMatch) {
            $null = $groupHeaders.Add($possibleGrouping)
            $rawValue = $values[0]
            $formattedValue = Format-GroupName $possibleGrouping $rawValue
            $null = $groupValues.Add($formattedValue)
        }
    }
    if ($groupHeaders) {
        "$($groupHeaders -join ', '): $($groupValues -join ' - ')"
    } else {
        $groupingValue
    }
}