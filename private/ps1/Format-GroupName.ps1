function Format-GroupName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,
        [Parameter(Mandatory)]
        [string]
        $Value
    )
    switch ($Name) {
        'Month' {
            $intVal = [int]$Value
            if ($intVal -ge 1 -and $intVal -le 12) {
                [cultureinfo]::InvariantCulture.DateTimeFormat.GetMonthName($intVal)
            } else { $Value }
        }
        Default {$Value}
    }
}