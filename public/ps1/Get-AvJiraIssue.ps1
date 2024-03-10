function Get-AvJiraIssue {
    <#
.SYNOPSIS
    Returns issues matching the given criteria: ID or Jira Query.
.DESCRIPTION
    Returns issues matching the given criteria: ID or Jira Query. When using query, will combine.
.EXAMPLE
    Get-AvJiraIssue [-Issue]  AAA-BBB, CCC-DDD
    returns specified issues (which include worklogs).
.PARAMETER Issue
    ID of issue. Can specify multiple, separated with a comma.
.PARAMETER Query
    Jira Query language string used to filter issues. More information: https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/
.PARAMETER Status
    Optionally limits issue to those with specified Status. Can provide multiple statuses (stati?).
.PARAMETER Assignee
    Optionally limits issue to those with specified Asignee. Can provide multiple assignees.
#>
    [CmdletBinding(DefaultParameterSetName = 'KEY')]
    [OutputType([Issue])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'KEY', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('IssueID')]
        [object[]]
        $Issue,
        [Parameter(ParameterSetName = 'QUERY')]
        [string]
        $Query,
        [Parameter(ParameterSetName = 'QUERY')]
        [Alias('User')]
        [string[]]
        $Assignee,
        [Parameter(ParameterSetName = 'QUERY')]
        [string[]]
        $Status
    )
    begin {

        $null = Get-AvJiraSession

        $local:outside_checkPerformed = $true # will skip session test for any subcommands
        $null = $local:outside_checkPerformed # to silence warnings about unused variable

    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'KEY') {

            Get-AvJiraIssue_Issue $Issue

        } else {
            $params = @{
                Query    = $Query
                Assignee = $Assignee
                Status   = $Status
            }
            Get-AvJiraIssue_Query @params

        }
    }
    end {
        Clear-WrappedProgress
        Write-Log "$($MyInvocation.MyCommand.Name) finished."
    }
}
