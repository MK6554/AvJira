$script:CertificateName = 'AvJiraEncrytingCertificate'
$script:EncryptedApiFileName = "JiraApi$($env:USERNAME).cms"
$script:CredentialSeparator = ';;;;____;;;;'
$script:AvJiraModulePath = $PSScriptRoot | Split-Path | Split-Path 
#                              ps1       |   private  |  [Version] 
$script:AvJiraModuleVersionsPath = $AvJiraModulePath | Split-Path
$script:EncryptedApiPath = Join-Path (Join-Path (Join-Path $script:AvJiraModulePath 'Private') 'cms') $script:EncryptedApiFileName
