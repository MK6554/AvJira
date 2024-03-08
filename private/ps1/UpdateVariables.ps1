$script:DateChecked = Get-Date -Year 1970
$script:NewerInstalled = $false
$script:Interval = [timespan]::FromHours(24)