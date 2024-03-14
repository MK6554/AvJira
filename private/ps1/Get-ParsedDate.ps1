function Get-ParsedDate {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Nullable[datetime]]
        $Date,
        [Parameter()]
        [timespan]
        $TimeSpent
    )
    if ($Date) {
        return $Date
    }
    $now = [datetime]::now - $TimeSpent
    $converter = [JiraDateTimeConverterAttribute]::new()
    while ($true) {
        $temp = Read-Host "Enter date of work (leave empty to use current date minus time spent: $now))"
        if ($temp -match '^\s*$') {
            # empty string
            $Date = $now
            Write-Host "Parsed date $Date"
            $Date
            break
        } else {
            try {
                $Date = $converter.Transform($temp)
                Write-Host "Parsed date $Date"
                $Date
                break
            } catch [System.ArgumentException] {
                Write-Host "$temp was not a valid date."
                Write-Host $converter.HelpMessage()
            }
        }
    }
}
