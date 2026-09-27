
<#
.SYNOPSIS
    Reports the on-prem OU of enabled Azure AD users whose last directory sync is older than 14 days,
    and lists the OUs of one domain.
.DESCRIPTION
    For every enabled Azure AD user it reads LastDirSyncTime. When it is older than 14 days (or empty, as
    for cloud-only users) it splits the user's onPremisesDistinguishedName into user name, domain, OU and
    parent DN and appends the result to $Exportpath. At the end it prints the unique parent OUs of the
    users whose domain matches '*wgbhq*' (collected in $finalwgbOU).
.NOTES
    Requires : AzureAD module and Connect-AzureAD.
    Setup    : set $Exportpath and the domain filter '*wgbhq*'.
    Check    : "-lt $cutoffDay" selects users NOT synced in the last 14 days - reverse the comparison if
               you want recently synced users.
    Known issues: for users that do not match, the previous user's result is appended to the CSV again
    (the Export-Csv line is outside the if). $ExportpathWGB is only used in a commented-out line.
#>


#55555555-5555-5555-5555-555555555551 clean cloud user



#55555555-5555-5555-5555-555555555552 dirty cloud user
$Exportpath="C:\A\SyncedOUtest.csv"
$ExportpathWGB="C:\A\WGBOUs.csv"
$today =get-date
$cutoffDay=$today.AddDays(-14)


#Connect-AzureAD

function get-theaaduser
{
Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $ObjectGUID
            
    )

$toreturn=Get-AzureADUser -ObjectId $ObjectGUID | Select-Object UserPrincipalName, LastDirSyncTime,AccountEnabled

return $toreturn
}



function get-ADUserOU{
Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $ObjectGUID
            
    )
    $i=1
    $j=1
    try{
        $UserOU =  (Get-AzureADUser -ObjectId $row | select -ExpandProperty ExtensionProperty)[“onPremisesDistinguishedName”]}catch{
                                return "error"}
    $split=$UserOU -split ","
    $count=$split.count
    $minus4 = $count -4
    $minus3 = $count -3
    $minus2 = $count -2
    $minus1 = $count -1
    $Domp1=$split[$minus3].trimstart("DC=")
    $domp2=$split[$minus2].replace('DC=','.')
    $domp3=$split[$minus1].replace('DC=','.')

    do{
        $OU+=$split[$i]
        $OU+=","
        $i++
        }while($i -le $minus4)

        $OU=$OU.TrimEnd(',')

     do{
        $DN+=$split[$j]
        $DN+=","
        $j++
        }while($j -le $minus1)
        
        $DN=$DN.TrimEnd(',')

    $obj = @()
    $obj += [PSCustomObject]@{ UserPrincipalName = $split[0].trimstart("CN=")
		                       Domain = $Domp1+ ' '+$domp2+' '+$domp3
                               OU = $OU
                               FUllDN = $DN
		                       
                              }
                              return $obj
    }






Clear-Variable -Name aadUsers
Clear-Variable result
Clear-Variable cusobj

$cusobj= @()
$aadUsers = Get-AzureADUser -All $true | Select DisplayName, ObjectId, userType

foreach($row in $aadUsers.Objectid){
    Clear-Variable currentaccount
    $currentaccount= get-theaaduser $row
    if($currentaccount.AccountEnabled -eq $true){
        if($currentaccount.LastDirSyncTime -lt $cutoffDay){
            $result=get-ADUserOU $row
            }
            $result|Export-Csv -Path $Exportpath -Append -NoTypeInformation -Force
            $cusobj += $result
      }      
    


}

$wgb= @()

foreach($row in $cusobj){
    if($row.domain -like '*wgbhq*'){
        $wgb += [PSCustomObject]@{ OUDN = $row.FUllDN             		                       
                              }
        
        }
        }
$wgbous=$wgb.OUDN|Sort-Object|Get-Unique #
#$wgbous | Export-Csv $ExportpathWGB
$finalwgbOU= @()

foreach($row in $wgbous){
    $finalwgbOU += [PSCustomObject]@{ OUDN = $row            		                       
                      }
                      }
                      $finalwgbOU
        

