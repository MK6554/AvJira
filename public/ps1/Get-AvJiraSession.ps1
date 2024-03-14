function Get-AvJiraSession {
    [Alias('Test-AvJiraSession')]
    [CmdletBinding()]
    param ( )
    Test-AvJiraUpdate
    if (-not (Get-JiraConfigServer)) {
        Write-Log 'Jira server is not configured!' -Warning
        $address = Read-Host 'Enter Jira server address (https://jira.[company].com)'
        Set-JiraConfigServer $address
    }
    $session = Get-JiraSession
    if (-not $session) {
        Update-Biedametry $MyInvocation.MyCommand.Name
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Start-Sleep -Milliseconds 200 # to ensure that progress bar shows up
        }
        Write-WrappedProgress -Activity 'Creating session...' -Auxiliary
        $key = Load-AvJiraApiKey
        if (-not $key) {
            $cred = Get-Credential -Message 'Saved credential not found. Provide username and password for this session. You can create saved credential with Set-AvJiraCredentials'
            $credentialSource = 'Manual type-in'
        } else {
            $username, $api = $key.split($script:CredentialSeparator, [System.StringSplitOptions]::RemoveEmptyEntries)
            $password = ConvertTo-SecureString $api -AsPlainText -Force -ErrorAction Stop
            $cred = New-Object System.Management.Automation.PSCredential ($username, $password)
            $credentialSource = 'Encrypted file'
        }
        $session = New-JiraSession -Credential $cred -ErrorAction SilentlyContinue -ErrorVariable $jiraSessionError
        if ($jiraSessionError) {
            Write-Error "Could not create a Jira session for the specified credentials (username: $username; source: $credentialSource)"
            Remove-JiraSession $session
            $session = $null
        } else {
            Write-Log 'Session created'
        }
        Write-WrappedProgress -Activity 'Creating session...' -Completed -Auxiliary
    }
    $session
}