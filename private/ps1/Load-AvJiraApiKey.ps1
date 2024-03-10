function Load-AvJiraApiKey {
    $key = Get-ChildItem $script:AvJiraModuleVersionsPath -Recurse -Filter $script:EncryptedApiFileName -Depth 3 | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $key) { return }
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $script:CertificateName
    if (-not $cert) { return }
    Write-Log "Using key $key"
    Unprotect-CmsMessage -Path $key.FullName
}