#Create Powershell obect with key and value

#parameters
$customobject=[PSCustomObject]@{
    ID1 = "x"
    ID2="y"
    ID3="Z"

}
$key="x"

get-key -Objectdetais $customobject -key $key
function get-key
{
    [CmdletBinding()]
    param (

        [PSCustomObject]
        $Objectdetais,
        # Parameter help description
        [string]
        $key
    )
   process{
    try{        
            $Keydetails=$Objectdetais | Format-List | Out-String -Stream | Select-String $key
            {
                Write-Host "The $key found in the object" + $Keydetails
            }        
        }
        catch {
            <#Do this if a terminating exception happens#>
        "Write-host" + $_
        }
     
   }
}

