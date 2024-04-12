function Get-AvJiraWorklog {
    <#
    .SYNOPSIS
        Returns worklogs from the given period or issue
    .DESCRIPTION
        Returns worklogs which are either from the given period or from specified issues.
    .PARAMETER Period
        Period of time from which logs should be fetched. Defaults to 'ThisMonth' if no specific issue is requested. If Issue is provided, defaults to 'AllTime'
    .PARAMETER User
        Optional user name to limit worklogs to. If fetching all issues from a period - defaults to currently logged user and CANNOT be empty. If fetching specific issue, is empty by default.
    .PARAMETER Issue
        Issue from which the logs will be fetched.
    .EXAMPLE
        Get-AvJiraWorkLog [-Period] LastMonth
        returns logs from last month for the logged in user
    .EXAMPLE
        Get-AvJiraWorkLog -User 'John Zebra'
        returns logs from last month for the user John Zebra
    .EXAMPLE
        Get-AvJiraWorkLog -User 'JZ0000'
        returns logs from last month for the user JZ0000 (John Zebra)
    #>
    #>
    [CmdletBinding(DefaultParameterSetName = 'DEFAULT')]
    param (
        [Parameter(Position = 0)]
        [System.Nullable[Period]]
        $Period = $null,
        [Parameter()]
        [Alias('Author')]
        [string[]]
        $User,
        [Parameter(ParameterSetName = 'ISSUE', ValueFromPipelineByPropertyName)]
        [object[]]
        $Issue,
        [Parameter(ParameterSetName='ISSUE')]
        [switch]
        $NoSubtasks
    )
    begin {
        $null = Get-AvJiraSession
        $local:outside_checkPerformed = $true # will skip session test for any subcommands
        $null = $local:outside_checkPerformed # to silence warnings about unused variable
        
    }
    process {
        Update-Biedametry $MyInvocation.MyCommand.Name $PSBoundParameters
        $issueMode = $PSCmdlet.ParameterSetName -eq 'ISSUE'
        $issueParams = @{}

        if ($null -eq $period) {
            $period = if ($issueMode) { [Period]::AllTime } else { [Period]::ThisMonth }
        }

        $query, $startDate, $endDate = Get-AvJiraQuery $period -silent:$issueMode

        
        if ($issueMode) {
            
            $issueParams['Issue'] = $Issue
            $issueParams['Subtasks'] = -not $NoSubtasks.IsPresent
            
        } else {
            #periodMode
            
            if (-not $User) {
                Write-Log "No username specified. Defaulting to credential's name."
                $User = (Get-JiraSession).UserName
            }

            $user = $user | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $queryParts = @($query)
            if (@($user).Count -eq 1) {

                $queryParts += @("worklogAuthor = '$user'")

            } elseif (@($user).Count -gt 1) {

                $user = $user | ForEach-Object { "'$_'" }
                $joined = '(' + ($user -join ', ') + ')'
                $queryParts += @("worklogAuthor in $joined")
            }
            $queryParts = $queryParts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $query = $queryParts -join ' AND '

            $issueParams['Query'] = $query
        }
        # Get-AvJiraIssue will behave differently depending on input parameters
        #$a = Get-AvJiraIssue @issueParams
        #$i = $a | get-AvJiraWorklog_Impl -StartDate $startDate -EndDate $endDate -Author $User
        #$worklogs = $i | Sort-Object Started -Descending
        $worklogs = Get-AvJiraIssue @issueParams | Get-AvJiraWorklog_Impl -StartDate $startDate -EndDate $endDate -Author $User | Sort-Object Started -Descending
        $worklogs | Tee-Object -Variable Global:AvJiraLastOutput
    }
    end {
        Clear-WrappedProgress
        Write-Log "$($MyInvocation.MyCommand.Name) finished."
    }
}
