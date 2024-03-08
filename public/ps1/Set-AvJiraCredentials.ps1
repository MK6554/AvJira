function Set-AvJiraCredentials {
    [CmdletBinding()]
    param (    )
    $Username = Read-Host 'Enter username'
    $ApiKey = Read-Host 'Enter password or API key' -AsSecureString
    $creds = New-Object System.Management.Automation.PSCredential($username, $ApiKey)
    $apikey = $creds.GetNetworkCredential().Password
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $CertificateName
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -DnsName $CertificateName -CertStoreLocation 'Cert:\CurrentUser\My' -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement -Type DocumentEncryptionCert -Verbose
    }
    if (Test-Path $EncryptedApiPath) {
        Remove-Item $EncryptedApiPath
    }
    $msg = "$username$Separator$apikey"
    $msg | Protect-CmsMessage -To "cn=$CertificateName" -OutFile $EncryptedApiPath -Verbose
}