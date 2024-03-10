function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]
        $Message,
        [Parameter()]
        [switch]
        $Warning
    )
    $Log = '[{0}] {1}' -f [string][datetime]::now.TimeOfDay.Tostring().substring(0, 12), $Message
    if ($error.IsPresent) {
        Write-Warning $Log
    } else {
        Write-Verbose $Log
    }
}