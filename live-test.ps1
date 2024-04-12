[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $PS5
)
$commands = "`$psversiontable.PSversion;(Measure-Command{ipmo $psscriptroot/AvJira.psd1 -verbose}).TotalSeconds"
$env:PSModulePath=$null
if ($PS5.IsPresent) {
    powershell -noexit -noprofile -command $commands
} else {
    pwsh -noexit -interactive -noprofile -wd $PSScriptRoot -command $commands
}