#requires -Modules EZOut

Write-FormatView -TypeName Worklog -VirtualProperty @{
    "Issue key" ={ $_.Issue.Key}
    "Issue summary" ={ $_.Issue.Summary}
    Comment = {if([string]::IsNullOrWhiteSpace($_.Comment)){"---No comment---"}else{$_.Comment}}
} -Property Author, TimeSpent -ColorProperty @{
    Comment =  {if([string]::IsNullOrWhiteSpace($_.Comment)){"`e[2m"}else{""}}
}