<#
.SYNOPSIS
    Exports each Azure AD user's on-premises distinguished name.
.DESCRIPTION
    For all Azure AD users, reads the onPremisesDistinguishedName extension property (filled for users
    synced from AD) and writes UPN, ObjectId and DN to C:\A\ContosoUsersDN.csv.
.NOTES
    Requires : AzureAD module and Connect-AzureAD.
    Setup    : set the Export-Csv path.
    Note     : cloud-only users have an empty DN. Get-AzureADUser is called again for every user, which
               is slow in large tenants.
#>


$all = Get-AzureADUser -All $true
$log = @()
Clear-variable log


$ObjectID = $null
$UPN = $null

foreach($line in $all)
    {Clear-Variable ObjectID,UPN
    $ObjectID = $line.ObjectId
    #$ObjectID
    $UPN = $line.UserPrincipalName

   $dn=(Get-AzureADUser -ObjectId $ObjectID | select -ExpandProperty ExtensionProperty)[“onPremisesDistinguishedName”]
   $log+= [PSCustomObject]@{ UPN = $UPN
                             ObjectId =  $ObjectID
                             DN =  $dn
    }
    }



    $log | Export-Csv -Path "C:\A\ContosoUsersDN.csv" -NoTypeInformation -Encoding UTF8
