function Set-AvJiraCredentials {
    [CmdletBinding()]
    param (    )
    $Username = Read-Host 'Enter username'
    $ApiKey = Read-Host 'Enter password or API key' -AsSecureString
    $creds = New-Object System.Management.Automation.PSCredential($username, $ApiKey)
    $apikey = $creds.GetNetworkCredential().Password
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $script:CertificateName
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -DnsName $script:CertificateName -CertStoreLocation 'Cert:\CurrentUser\My' -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement -Type DocumentEncryptionCert -Verbose
    }
    if (Test-Path $script:EncryptedApiPath) {
        Remove-Item $script:EncryptedApiPath
    }
    $msg = "$username$script:CredentialSeparator$apikey"
    $null = New-Item -ItemType Directory -Path (Split-Path $script:EncryptedApiPath) -Force
    $msg | Protect-CmsMessage -To "cn=$script:CertificateName" -OutFile $script:EncryptedApiPath -Verbose
    $oldSession = Get-JiraSession
    if ($oldSession) {
        Remove-JiraSession $oldSession
    }
    New-JiraSession $creds
}