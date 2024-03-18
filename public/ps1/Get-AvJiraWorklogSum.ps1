function Get-AvJiraWorklogSum {
    <#
    .SYNOPSIS
        Sums up given collection of worklogs.
    .DESCRIPTION
        Return total time spent from given groupedItemList. This cmdlet should be used in pipeline (with the | operator).
        You can specify how the logs should be grouped before summation (see -GroupBy).
        Specifying a feature that does not exist will result in no grouping.

        You can also pipe in to the cmdlet already grouped objects (or arrays).
        The cmdlet will attempt to find out how the logs are grouped (by month, year, etc.) which will be displayed in header.
    .PARAMETER GroupBy
        Optional name of the worklog property which will be used to group logs before summing them up.
        You can specify multiple properties (e.g. year, month)
    .EXAMPLE
        get-avjiraworklog | logsum

        Sums all logs from current month
    .EXAMPLE
        get-avjiraworklog ThisYear | logsum -Group Month

        Sums all logs from this year, grouped by Month. ('-Group' can be omitted)
    .EXAMPLE
        get-avjiraworklog ThisYear | logsum Issue

        Sums all logs from this year, grouped by Issue.
    .EXAMPLE
        get-avjiraworklog ThisYear | group Month | logsum
        
        Sums all logs from this year, grouped by Month
    EXAMPLE
        get-avjiraworklog ThisYear | logsum Yar, Month

        Sums all logs from this year, grouped by Year, then month.
    #>
    
    [CmdletBinding()]
    [Alias('logsum')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Group')] # should take care of using GroupInfo as input.
        [object]
        $Worklog,
        [Parameter(Position = 0)]
        [string[]]
        $GroupBy
    )
    begin {
        Update-Biedametry $MyInvocation.MyCommand.Name $PSBoundParameters
        # list for ungrouped logs
        $singleItemList = [System.Collections.Generic.List[Worklog]]::new()
    }
    process {
        if ($worklog -is [Worklog]) {
            # if we received one worklog (as in items are fed 1 by one to pipeline)
            # add it to the first list
            $singleItemList.add($Worklog)
        } elseif ($worklog -is [System.Collections.IEnumerable]) {
            # we have received a collection of logs
            # assume they are from a group
            # create sum immediately
            $array = @($worklog)
            [SummedWorklogs]::new($array, (Find-WorklogGroupingObject $array -groupingValue $null ))
        } elseif ($worklog -is [Microsoft.PowerShell.Commands.GroupInfo]) {
            # we have received a collection of logs
            # assume they are from a group
            # create sum immediately
            [SummedWorklogs]::new($worklog.Group, (Find-WorklogGroupingObject $worklog.Group -groupingValue $worklog.Name ))
        }
    }
    end {
        if ($Groupby) {
            # if user want to group, group by the specified property and return summ for each group.
            $groups = $singleItemList | Sort-Object Started | Group-Object $GroupBy
            foreach ($g in $Groups) {
                [SummedWorklogs]::new($g.Group, (Find-WorklogGroupingObject $g.Group -groupingValue $g.Name ))
            }
        } elseif ($singleItemList) {
            # return sum of all logs.
            $array = @($singleItemList)
            [SummedWorklogs]::new($array, (Find-WorklogGroupingObject $array -groupingValue $null ))
        }
    }
}