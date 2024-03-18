function Find-WorklogGroupingObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]
        $Logs,
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [object]
        $GroupingValue
    )
    $possibleGroupings = @('Month', 'Year', 'Issue', 'Key', 'Summary', 'Day', 'Id')
    foreach ($possibleGrouping in $possibleGroupings) {
        $values = $Logs.$possibleGrouping | Select-Object -Unique
        $isOne = $values.count -eq 1
        $isMatch = if ($isOne -and $GroupingValue) { $GroupingValue -eq $values[0] } else { $true }
        if ($isOne -and $isMatch) {
            $rawValue = $values[0]
            $val = switch ($possibleGrouping) {
                'Month' {
                    if ($rawValue -ge 1 -and $rawValue -le 12) {
                        $years = $logs.year | Select-Object -Unique
                        "$([cultureinfo]::InvariantCulture.DateTimeFormat.GetMonthName($rawValue)) $($years -join ', ')"
                    }
                }
                default { $rawValue }
            }
            if (-not $val) { continue }
            return "$possibleGrouping`: $val"
        }
    }

    return "Logs $groupingValue"
}