Push-Location $psscriptRoot
$moduleName = 'AvJira'
$folderToExport = Join-Path $PSScriptRoot $moduleName
if (Test-Path $folderToExport) {
    Remove-Item $folderToExport -Force -Recurse -Verbose
}
$dirs = Get-ChildItem $PSScriptRoot -Directory
$FolderFiles = $dirs | ForEach-Object {
    Get-ChildItem $_.FullName -Recurse -File | Where-Object Extension -NotIn @('.cms', '.gitignore')
}
$RootFiles = Get-ChildItem $PSScriptRoot -File | Where-Object Extension -NotIn @('.ps1', '.gitignore')
$Files = @($RootFiles) + @($FolderFiles)


Write-Host 'Copying files'
foreach ($file in $Files) {
    $relative = Resolve-Path $file.FullName -Relative -RelativeBasePath $PSScriptRoot
    $newPath = Join-Path $folderToExport $relative
    $newPathFolder = Split-Path $newPath
    $null = New-Item -item Directory -Path $newPathFolder -Force
    Copy-Item $file.fullname -Destination $newPath -Force -Verbose
}
$import = Get-ChildItem $folderToExport *.psd1 | Select-Object -First 1
Import-Module $import.FullName -Force -Verbose -EA SilentlyContinue
Publish-Module -Path $moduleName -Repository PowershellSupportRepository
Pop-Location
