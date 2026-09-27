<#
.SYNOPSIS
    Exports name, sAMAccountName and proxy addresses of all users in an OU.
.DESCRIPTION
    Reads every user under the OU in $DN (including sub-OUs) and writes Name, UserPrincipalName,
    samaccountname and ProxyAddress (all addresses, one per line) to the CSV path in the Export-Csv line.
    Errors are appended to $errorPath.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $DN, $errorPath and the Export-Csv path.
    Known issue: the property is misspelled as "UserPrincipalNam", so the UserPrincipalName column is
    empty.
#>


$DN = "OU=Users,OU=Fabrikam,DC=fabrikam,DC=com"
$errorPath="C:\Temp\error.txt"
try{$users=get-aduser -filter * -SearchBase $DN -Properties ProxyAddresses | select Name, UserPrincipalNam, samaccountname, ProxyAddresses
    }catch {
  "An error occurred:"|Out-file -FilePath $errorPath -Append
   $_ |Out-file -FilePath $errorPath -Append
}
$obj = @()
foreach($item in $users) {
    $item  
$obj += [PSCustomObject]@{ Name = $item.Name
		                   UserPrincipalName = $item.UserPrincipalNam|Out-String
		                   samaccountname = $item.samaccountname
		                   ProxyAddress =  $item.ProxyAddresses|Out-String
}

}

try{$obj | Export-Csv -Path "C:\Temp\FabrikamUserList.csv" -Delimiter "," -Encoding UTF8 -NoTypeInformation
    }catch {
   "An error occurred:"|Out-file -FilePath $errorPath -Append
   $_ |Out-file -FilePath $errorPath -Append
}
