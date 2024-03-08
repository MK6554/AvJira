class JiraTimeSpanConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [timespan]) {
            return $inputData
        } elseif ($inputData -is [int]) {
            return [timespan]::FromMinutes($inputData)
        } elseif ($inputData -is [string]) {
            [string[]]$formats = @(
                'hh\:mm\', 
                'hhmm', 
                'mm', 
                'hh\hmm\m', 
                'hh\hm\m', 
                'h\hmm\m', 
                'h\hm\m', 
                'hh\h',
                'h\h',
                'mm\m'
                'm\m'
            )
            [timespan]$result = 0
            $inputStr = $inputData -replace '[^hHmM\d:]', ''
            if ([timespan]::TryParseExact($inputStr, $formats, $null, [ref]$result)) {
                return $result
            }
        }
        throw [System.ArgumentException]::new('Cannot convert to timespan')
    }
}