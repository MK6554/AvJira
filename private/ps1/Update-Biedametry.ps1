$script:BiedametryPath = 'None'
function Update-Biedametry ([string]$name, $params) {
    if ($script:BiedametryPath -eq 'None') {
        $script:BiedametryPath = Get-PSRepository -Name PowershellSupportRepository | ForEach-Object SourceLocation
    }
    if (-not $script:BiedametryPath) {
        return 
    }
    $user = $env:COMPUTERNAME
    $date = Get-Date
    $datename = $date.tostring('yyyyMMdd')
    $destinationFolder = Join-Path $script:BiedametryPath Biedametry
    $destinationUserFolder = Join-Path $destinationFolder $user
    if (-not (Test-Path $destinationUserFolder)) {
        New-Item -ItemType Directory $destinationUserFolder -Force
    }
    $destination = Join-Path $destinationUserFolder "$datename.json"

    $contentSource = if (Test-Path $destination) {
        Get-Content $destination -Raw
    } else { @() }

    [object[]]$content = $contentSource | ConvertFrom-Json

    $keys = if ($params.keys) {
        @($params.keys)
    } else {
        @()
    }
    foreach ($k in $keys ) {
        if ($params[$k] -is [Period]) {
            $params[$k] = $params[$k].tostring()
        }
    }

    $val = [pscustomobject]@{
        Function = $Name
        Date     = $date.tostring('O')
        Params   = $params
    }
    $content += @($val)
    $content | ConvertTo-Json -Depth 3 | Out-File -FilePath $destination
}