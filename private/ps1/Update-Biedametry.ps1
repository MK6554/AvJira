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

    $content = if (Test-Path $destination) {
        Get-Content $destination -raw
    } else { @() }

    $content = $content | ConvertFrom-Json -NoEnumerate

    $val = [pscustomobject]@{
        Function = $Name
        Date     = $date#.tostring('yyyy-MM-dd HH:mm:ss.') + $date.Millisecond.tostring().PadLeft(3, '0')
        Params   = $params
    }
    $content += @($val)
    $content | ConvertTo-Json -AsArray -EnumsAsStrings -Depth 3 | Out-File -FilePath $destination
}