class JiraDateTimeConverterAttribute:System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData) {
        if ($inputData -is [datetime]) {
            return $inputData
        } elseif ($inputData -is [int] -and $inputData -le 0) {
            return [datetime]::Now.AddDays($inputData)
        } elseif ($inputData -is [string]) {
            [string[]]$formats = @(
                'yyyyMMdd', 
                'MMdd', 
                'dd',
                'yyyyMMddhhmm', 
                'MMddhhmm', 
                'ddhhmm',
                'yyyyMMdd', 
                'MMdd', 
                'dd'
            )
            [datetime]$result = 0
            $inputStr = $inputData -replace '[\D]', ''
            if ([datetime]::TryParseExact($inputStr, $formats, $null, [System.Globalization.DateTimeStyles]::None, [ref]$result)) {
                if ($result.TimeOfDay -eq [timespan]::Zero) {
                    $result = $result.Add([datetime]::now.TimeOfDay)
                }
                return $result
            }
        }
        throw [System.ArgumentException]::new('Cannot convert to datetime')
    }
}