[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $PS5
)
$commands = '$psversiontable.PSversion;(Measure-Command{ipmo ./AvJira.psd1 -verbose}).TotalSeconds'
if ($PS5.IsPresent) {
    powershell -noexit -noprofile -command $commands
} else {
    pwsh -noexit -interactive -noprofile -wd $PSScriptRoot -command $commands
}