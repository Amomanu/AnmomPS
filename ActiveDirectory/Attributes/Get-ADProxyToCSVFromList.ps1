<#
.SYNOPSIS
    Exports the UPN and proxy addresses of the AD users listed in a CSV.
.DESCRIPTION
    For each sAMAccountName in the SourceName column of $inpath, reads the user's UserPrincipalName and
    proxyAddresses from AD and writes UserPrincipalName, samaccountname and ProxyAddress to $outpath.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $inpath and $outpath (both are the placeholder "C:\path.csv" - use two different files).
#>


$inpath="C:\path.csv"
$outpath="C:\path.csv"

function Get-UserSMTP{

Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $UserSam
            
    )

    return (get-aduser -identity $UserSam -Properties ProxyAddresses | select  UserPrincipalName, samaccountname, ProxyAddresses)

}

Clear-Variable obj | Out-Null

$obj = @()



$csvIN=Import-Csv -Path $inpath
foreach($sam in $csvIN.SourceName){
$res=Get-UserSMTP $sam
#$res.samaccountname,$res.ProxyAddresses
$obj += [PSCustomObject]@{ UserPrincipalName = $res.UserPrincipalName|Out-String
		                   samaccountname = $res.samaccountname
		                   ProxyAddress =  $res.ProxyAddresses|Out-String
                           }




}

$obj|Export-Csv  -Path $outpath -notypeinformation


            
