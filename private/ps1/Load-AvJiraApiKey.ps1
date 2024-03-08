$CertificateName = 'AvJiraEncrytingCertificate'
$EncryptedApiFileName = "JiraApi$($env:USERNAME).cms"
$AvJiraModulePath = $PSScriptRoot | Split-Path | Split-Path 
#                       ps1       |   private  |  [Version] 
$AvJiraModuleVersionsPath = $AvJiraModulePath | Split-Path 
#                                                 AvJira
function Load_AvJiraApiKey {
    $key = Get-ChildItem $AvJiraModuleVersionsPath -Recurse -Filter $EncryptedApiFileName -Depth 3 | Sort-Object LastWriteTime | Select-Object -First 1
    if (-not $key) { return }
    $cert = Get-ChildItem Cert:\CurrentUser\My -DnsName $CertificateName
    if (-not $cert) { return }
    Unprotect-CmsMessage -Path $key.FullName
}