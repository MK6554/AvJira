function Get-AvJiraIssue {
    <#
.SYNOPSIS
    Returns issues matching the given criteria: ID or Jira Query.
.DESCRIPTION
    Returns issues matching the given criteria: ID or Jira Query.
.EXAMPLE
    Get-AvJiraIssue [-Issue]  AAA-BBB, CCC-DDD
    returns specified issues (which include worklogs)
.PARAMETER Issue
    ID of issue. Can specify multiple, separated with a comma
.PARAMETER Query
    Jira Query language string used to filter issues. More information: https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/
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
        [string[]]
        $User,
        [Parameter(ParameterSetName = 'QUERY')]
        [string[]]
        $Status
    )
    begin {

        Test-AvJiraSession

        $local:outside_checkPerformed = $true # will skip session test for any subcommands
        $null = $local:outside_checkPerformed # to silence warnings about unused variable

        Write-WrappedProgress -Activity 'Fetching issues...' -Status 'Contacting server...'

    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'KEY') {

            Get-AvJiraIssue_Issue $input

        } else {
            $params = @{
                Query  = $Query
                User   = $User
                Status = $Status
            }
            Get-AvJiraIssue_Query @params

        }
    }
    end {

        Write-WrappedProgress -Activity 'Parsing issues...' -Status 'Done' -Completed

    }
}
