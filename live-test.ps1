$commands = "ipmo ./AvJira.psd1; `$q=get-avjiraworklog lastmonth;`$w=`$q[0].Issue;`$q"
if ($args[0]) {
    powershell -noexit -noprofile  -command $commands
} else {
    pwsh -noexit -interactive -noprofile -wd $PSScriptRoot -command $commands
}