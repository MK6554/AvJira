function Get-AvJiraQuery {
    param (
        [Period]
        $Period
    )
    $periodStr = if ($Period -eq 'Today') { 'ThisDay' }elseif ($Period -eq 'Yesterday') { 'LastDay' }else { $period.TOstring() }
    $methodStem = $periodStr.Substring(4)
    $arg = if ($periodStr -like 'This*') { 0 }else { -1 }
    $startDateQuery = 'startOf' + $methodStem + "($arg)"
    $endDateQuery = 'endOf' + $methodStem + "($arg)"
    $query = "worklogDate >= $startDateQuery AND worklogDate < $endDateQuery"
    
    $thisDayStart = [datetime]::Today
    $thisWeekStart = [datetime]::today.adddays( - [int]$thisDayStart.DayOfWeek + 1) # jira starts week on Sunday (xDDDD); +1 because dayofweek enum starts at 1 so it would subtract to saturday
    $thisMonthStart = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0
    $thisyearStart = Get-Date -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
    
    $startDatetime, $endDateTime = if ($methodStem -eq 'Month') {
        $thisMonthStart.AddMonths($arg)
        $thisMonthStart.AddMonths($arg + 1).AddSeconds(-1)
    } elseif ($methodStem -eq 'Week') {
        $thisWeekStart.AddDays($arg * 7)
        $thisWeekStart.AddDays(($arg + 1) * 7).AddSeconds(-1)
    } elseif ($methodStem -eq 'Year') {
        $thisyearStart.AddYears($arg)
        $thisyearStart.AddYears($arg + 1).AddSeconds(-1)
    } else {
        #day
        $thisDayStart.AddDays($arg)
        $thisDayStart.AddDays($arg + 1).AddSeconds(-1)
    }

    $query, $startDateTime, $endDateTime
}