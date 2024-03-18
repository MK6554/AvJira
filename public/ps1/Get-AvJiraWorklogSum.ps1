function Get-AvJiraWorklogSum {
    <#
    .SYNOPSIS
        Sums given groupedItemList up.
    .DESCRIPTION
        Return total time spent from given groupedItemList. This cmdlet should be used in pipeline (with the | operator)
    .EXAMPLE
        get-avjiraworklog | logsum

        Sums all logs from current month
    .EXAMPLE
        get-avjiraworklog ThisYear | logsum -Group Month

        Sums all logs from this year, grouped by Month
    .EXAMPLE
        get-avjiraworklog ThisYear | group Month | logsum
        
        Sums all logs from this year, grouped by Month
    #>
    
    [CmdletBinding()]
    [Alias('logsum')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Group')] # should take care of using GroupInfo as input.
        [object]
        $Worklog,
        [Parameter(Position=0)]
        [string]
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
            [SummedWorklogs]::new(@($worklog))
        }elseif ($worklog -is [Microsoft.PowerShell.Commands.GroupInfo]) {
            # we have received a collection of logs
            # assume they are from a group
            # create sum immediately
            [SummedWorklogs]::new($worklog.Group)
        }
        
    }
    end {
        if (-not [string]::IsNullOrWhiteSpace($GroupBy)) {
            # if user want to group, group by the specified property and return summ for each group.
            $groups = $singleItemList | Sort-Object Started | Group-Object $GroupBy
            foreach ($g in $Groups) {
                [SummedWorklogs]::new(@($g.Group))
            }
        } elseif ($singleItemList) {
            # return sum of all logs.
            [SummedWorklogs]::new(@($singleItemList))
        }
    }
}