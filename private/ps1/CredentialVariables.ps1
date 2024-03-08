$script:CertificateName = 'AvJiraEncrytingCertificate'
$script:EncryptedApiFileName = "JiraApi$($env:USERNAME).cms"
$script:AvJiraModulePath = $PSScriptRoot | Split-Path | Split-Path 
#                       ps1       |   private  |  [Version] 
$script:Separator = ';;;;____;;;;'
$script:AvJiraModuleVersionsPath = $AvJiraModulePath | Split-Path
$script:EncryptedApiPath = Join-Path (Join-Path (Join-Path $script:AvJiraModulePath 'Private') 'cms') $script:EncryptedApiFileName