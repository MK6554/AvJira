function Set-PrivateData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        $Value
    )
    $privData = $MyInvocation.MyCommand.Module.PrivateData
    if ($null -ne $MyInvocation.MyCommand.Module.PrivateData) {
        $privData[$DataName] = $Value

    } else {

        $MyInvocation.MyCommand.Module.PrivateData = @{
            $Name = $Value
        }

    }
}