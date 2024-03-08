# Join-Path works differently on 5, otherwise would have used it
$dirSep = [System.IO.Path]::DirectorySeparatorChar
$moduleName = $MyInvocation.MyCommand.Name -replace '\.ps.1', ''
$moduleManifest = $PSScriptRoot + $dirSep + $moduleName + '.psd1'
$publicFunctionsPath = $PSScriptRoot + $dirSep + 'Public' + $dirSep + 'ps1'
$privateFunctionsPath = $PSScriptRoot + $dirSep + 'Private' + $dirSep + 'ps1'
#$classesPath =  $PSScriptRoot + $dirSep + 'Classes' + $dirSep + 'ps1'
$formatFilesPath = $PSScriptRoot + $dirSep + 'Public' + $dirSep + 'format'
$typesFilesPath = $PSScriptRoot + $dirSep + 'Public' + $dirSep + 'types'
$currentManifest = Test-ModuleManifest $moduleManifest

$aliases = @()

$publicFunctions = Get-ChildItem -Path $publicFunctionsPath -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ps1' }
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ps1' }

$formatFiles = Get-ChildItem -Path $formatFilesPath -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ps1xml' }
$typesFiles = Get-ChildItem -Path $typesFilesPath -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ps1xml' }

$privateFunctions | ForEach-Object { . $_.FullName }
$publicFunctions | ForEach-Object { . $_.FullName }

$publicFunctions | ForEach-Object { # Export all of the public functions from this module
    # The command has already been sourced in above. Query any defined aliases.
    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    } else {
        Export-ModuleMember -Function $_.BaseName
    }
}

$formatFiles | ForEach-Object { # Export format data from module
    Update-FormatData -PrependPath $_.FullName 
}

$typesFiles | ForEach-Object { # Export type data from module
    #Update-TypeData -PrependPath $_.FullName
}

$functionsAdded = $publicFunctions | Where-Object { $_.BaseName -notin $currentManifest.ExportedFunctions.Keys }
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object { $_ -notin $publicFunctions.BaseName }
$aliasesAdded = $aliases | Where-Object { $_ -notin $currentManifest.ExportedAliases.Keys }
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object { $_ -notin $aliases }

$currentFormatsNames = $currentManifest.ExportedFormatFiles | Split-Path -Leaf
$currentTypesNames = $currentManifest.ExportedTypeFiles | Split-Path -Leaf

$formatsAdded = $formatFiles | Where-Object { $_.Name -notin $currentFormatsNames }
$formatsRemoved = $currentFormatsNames | Where-Object { $_ -notin $formatFiles.Name }
$typesAdded = $typesFiles | Where-Object { $_.Name -notin $currentTypesNames }
$typesRemoved = $currentTypesNames | Where-Object { $_ -notin $typesFiles.Name }

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved -or $formatsAdded -or $formatsRemoved -or $typesAdded -or $typesRemoved) {

    try {

        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $moduleManifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
        if ($publicFunctions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $publicFunctions.BaseName) }
        if ($formatFiles.Count -gt 0) { $updateModuleManifestParams.Add('FormatsToProcess', ($formatFiles.FullName | Resolve-Path -Relative -RelativeBasePath $PSScriptRoot)) }
        if ($typesFiles.Count -gt 0) { $updateModuleManifestParams.Add('TypesToProcess', ($typesFiles.FullName | Resolve-Path -Relative -RelativeBasePath $PSScriptRoot)) }

        Update-ModuleManifest @updateModuleManifestParams

    } catch {

        $_ | Write-Error

    }

}