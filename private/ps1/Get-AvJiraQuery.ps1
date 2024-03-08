function Get-AvJiraQuery {
    param (
        [Period]
        $Period,
        [Switch]
        $Silent
    )
    $periodStr = if ($Period -eq 'Today') { 'ThisDay' }elseif ($Period -eq 'Yesterday') { 'LastDay' }else { $period.TOstring() }
    $methodStem = $periodStr.Substring(4)
    $arg = if ($periodStr -like 'This*') { 0 }else { -1 }
    $startDateQuery = 'startOf' + $methodStem + "($arg)"
    $endDateQuery = 'endOf' + $methodStem + "($arg)"
    $query = "worklogDate >= $startDateQuery AND worklogDate < $endDateQuery"
    
    $thisDayStart = [datetime]::Today
    $thisWeekStart = $thisDayStart.AddDays( - [int]$thisDayStart.DayOfWeek + 1) # jira starts week on Sunday (xDDDD); +1 because dayofweek enum starts at 1 so it would subtract to saturday
    $thisMonthStart = $thisDayStart.AddDays(- $thisDayStart.Day + 1) # subtract day of month (goes to previous month), add back 1 day (to go to current month)
    $thisyearStart = $thisDayStart.AddDays(- $thisDayStart.DayOfYear + 1) # subtract day of month (goes to previous year), add back 1 day (to go to current year)

    $startDatetime, $endDateTime = if ($methodStem -eq 'Month') {
        $thisMonthStart.AddMonths($arg)
        $thisMonthStart.AddMonths($arg + 1).AddSeconds(-1)
    } elseif ($methodStem -eq 'Week') {
        $thisWeekStart.AddDays($arg * 7)
        $thisWeekStart.AddDays(($arg + 1) * 7).AddSeconds(-1)
    } elseif ($methodStem -eq 'Year') {
        $thisyearStart.AddYears($arg)
        $thisyearStart.AddYears($arg + 1).AddSeconds(-1)
    } elseif ($methodStem -eq 'Day') {
        $thisDayStart.AddDays($arg)
        $thisDayStart.AddDays($arg + 1).AddSeconds(-1)
    } else {
        #All
        if (-not $Silent.IsPresent) {
            Write-Log 'Getting issue without time limits might be really slow!' -warning
        }
        [datetime]::MinValue
        [datetime]::MaxValue
        $query = ''
    }

    $query, $startDateTime, $endDateTime
}

