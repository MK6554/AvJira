class Worklog {
    [Issue]$Issue
    [datetime]$Started
    [datetime]$Created
    [timespan]$TimeSpent
    [int]$TimeSpentSeconds
    [string]$Comment
    [Person]$Author
    Worklog([pscustomobject]$jiraLogObject, [Issue]$parent) {
        $this.Issue = $parent
        $this.Author = [Person]::new($jiraLogObject.author)
        $this.Comment = $jiraLogObject.Comment
        $this.Started = $jiraLogObject.Started
        $this.Created = $jiraLogObject.Created
        $this.TimeSpent = [timespan]::FromSeconds($jiraLogObject.timespentseconds)
    }
}
$barParams = @{
    ID       = 2137
    ParentID = 420
}