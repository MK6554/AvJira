function Get-ParsedTime {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Nullable[timespan]]
        $Time
    )
    if ($Time) {
        return $time
    }
    $converter = [JiraTimeSpanConverterAttribute]::new()
    while ($true) {
        $temp = Read-Host 'Enter time spent'
        try {
            $Time = $converter.Transform($temp)
            Write-Host "Parsed time $($Time.tostring('hh\h\ mm\m'))"
            $Time
            break
        } catch [System.ArgumentException] {
            Write-Host "$temp was not invalid time format."
            Write-host $converter.HelpMessage()
        }
    }
}