<#
.SYNOPSIS
    Replaces all proxyAddresses of AD users with the addresses given in a CSV and keeps a backup of the
    old ones.
.DESCRIPTION
    For each row of the input CSV (columns samaccountname and ProxyAddress) it saves the user's current
    proxyAddresses, removes every existing proxy address one by one, then adds the addresses from the
    ProxyAddress column (split on commas). The removed addresses are exported to $OldProxiesPath and
    errors are appended to $errorPath.
.NOTES
    WARNING  : destructive - every existing proxy address is removed before the new ones are added.
               Test on one user first and keep the backup file.
    Requires : ActiveDirectory module.
    Setup    : set the Import-Csv path, $OldProxiesPath and $errorPath ($CurrentProxiesPath is not used).
               The ProxyAddress column must hold the complete new list, comma-separated, for example
               SMTP:first.last@contoso.com,smtp:alias@contoso.com. The default input path is the output
               of GetProxyAddressToCSV.ps1, whose ProxyAddress column is newline-separated - convert it
               to comma-separated first.
    Note     : in the backup file only samaccountname and ProxyAddress are filled (Name and
               UserPrincipalName stay empty because of variable typos).
#>


$CurrentProxiesPath="C:\Temp\CurrentProxybeforeswitch.csv"
$OldProxiesPath="C:\Temp\OldProxies.csv"
$errorPath = "C:\Temp\error - writeProxy.txt"
$z=Import-Csv "C:\Temp\FabrikamUserList.csv"
$obj = @()



foreach ($row in $z)

{#$row.samaccountname
$email=$row.ProxyAddress #email
try{$current = (get-aduser $row.samaccountname -Properties ProxyAddresses | select Name, UserPrincipalNam, samaccountname, ProxyAddresses)}catch{
  "GetUserError : An error occurred for user " +  $row.samaccountname  + ":"|Out-file -FilePath $errorPath -Append
    $_ |Out-file -FilePath $errorPath -Append
}  #Per user
$obj += [PSCustomObject]@{ Name = $item.Name 
		                   UserPrincipalName = $current.UserPrincipalNam|Out-String
		                   samaccountname = $current.samaccountname
		                   ProxyAddress =  $current.ProxyAddresses|Out-String   #Saves in variable data to write to file -what will get removed-
} 
$currentproxies=$current.ProxyAddresses  #email addresses per smtp
foreach ($line in $currentproxies)
    { 
    #$line
    try{Set-ADUser -Identity $row.samaccountname -remove @{ ProxyAddresses = $line } -Verbose}catch{  #Removes each smtp address line by line
    "RemoveProxy error occurred for user " +  $row.samaccountname  + ":"|Out-file -FilePath $errorPath -Append
    $_ |Out-file -FilePath $errorPath -Append}
    }

try{Set-ADUser $row.samaccountname -add @{ProxyAddresses="$email" -split ","} }catch{  #Sets email address based on the CSV value
  "SettingNewProxy error occurred for user " +  $row.samaccountname  + ":"|Out-file -FilePath $errorPath -Append
    $_ |Out-file -FilePath $errorPath -Append
}
#Clear-Variable current
} 

try{$obj | Export-Csv -Path $OldProxiesPath -Delimiter "," -Encoding UTF8 -NoTypeInformation   #Writing proxies removed to file
    }catch {
   "An error occurred writing the old proxies file :"|Out-file -FilePath $errorPath -Append
   $_ |Out-file -FilePath $errorPath -Append
}
