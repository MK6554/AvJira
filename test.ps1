Import-Module .\AvJira.psd1 -Force
$a = get-avjiraworklog thisyear 
$a | logsum month