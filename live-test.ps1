[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $PS5
)
$commands = '$psversiontable.PSversion;ipmo jiraps;ipmo ./AvJira.psd1'
if ($PS5.IsPresent) {
    powershell -noexit -noprofile -command $commands
} else {
    pwsh -noexit -interactive -noprofile -wd $PSScriptRoot -command $commands
}