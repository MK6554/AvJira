function Get-ParsedDate {
    param (
        [Parameter()]
        [object]
        $Date
    )
    if ($Date) {
        return $Date
    }
    $now = [datetime]::now
    while ($true) {
        $temp = Read-Host "Enter date of work (leave empty to use current date: $now))"
        if ($temp -notmatch '[\d-:]+') {
            $Date = $now
            break
        } else {
            try {
                $Date = [JiraDateTimeConverterAttribute]::new().Transform($null, $temp)
                break
            } catch [System.ArgumentException] {
                Write-Host "$temp was not a valid date. Try again (yyyy-mm-dd)."
            }
        }
    }
}
