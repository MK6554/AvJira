function Get-CapitalizedString ([string]$x){
    if($x.length -le 1){
        $x.ToUpper()
    }
    else{
        $x.Substring(0,1).ToUpper() + $x.Substring(1,$x.Length-1)
    }
}