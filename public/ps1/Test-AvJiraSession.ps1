$script:OutdatedVersionOnPurpose = $false
$Separator = ';;;;____;;;;'
function Test-AvJiraSession {
    Test-AvJiraUpdate
    if (-not (Get-JiraConfigServer)) {
        Write-Warning 'Jira server is not configured!'
        $address = Read-Host 'Enter Jira server address (https://jira.[company].com)'
        Set-JiraConfigServer $address
    }
    if (-not (Get-JiraSession)) {
        Write-Verbose 'No session active. Creating...'
        $key = Load_AvJiraApiKey
        if (-not $key) {
            $cred = Get-Credential -Message 'Saved credential not found. Provide username and password for this session. You can create saved credential with Set-(AvJira)Credentials'
        } else {
            $username, $api = $key.split($Separator, [System.StringSplitOptions]::RemoveEmptyEntries)
            $password = ConvertTo-SecureString $api -AsPlainText -Force -ErrorAction Stop
            $cred = New-Object System.Management.Automation.PSCredential ($username, $password)
        }
        $null = New-JiraSession -Credential $cred
    }
}