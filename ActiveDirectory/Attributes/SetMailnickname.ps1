<#
.SYNOPSIS
    Copies each synced user's cloud mailNickname to the on-prem AD user when the two differ.
.DESCRIPTION
    Reads all Azure AD users. For every directory-synced user it finds the AD user with the same UPN and,
    when the on-prem mailNickname differs from the cloud MailNickName, writes the cloud value to AD on
    $server and reads it back. Entries written to $logs:
      - "Success" or "Fail" for synced users whose value differed (see the known issue about "Fail");
      - "Fail.No on-prem users" for cloud-only (not synced) users;
      - "Fail.Could not find on-prem user" only when the AD lookup itself throws an error (that user then
        also gets a "Fail" entry).
    Synced users whose values already match get no entry. A synced user with no matching AD account is
    logged as plain "Fail".
.NOTES
    Requires : AzureAD module (Connect-AzureAD) and ActiveDirectory module.
    Setup    : set $server to a domain controller (the "$server =" line is left empty as shipped).
    Output   : results stay in the $logs variable (nothing is exported).
    Known issue: the read-back check compares an object with a string, so users are logged as "Fail"
    even when the change worked - verify in AD. Test on a few users first: it changes AD for every
    mismatched synced user.
#>


$server = #Place name of dc to use


$logs = @()
$i = 1

$AzureADUsers = get-azureaduser -all $true
foreach($user in $AzureADUsers){
    $cloudNickname = $null            #Cleaning all variables at the start
    $UPN =$null
    $localUser = $null
    $OnPremNickname = $null
    $samaccountname = $null
    $OnPremDN = $null
    $synced = $null
    $CloudObjID = $null

    $cloudNickname = $user.MailNickName
    $UPN= $user.UserPrincipalName
    $synced = $user.DirSyncEnabled
    $CloudObjID = $user.ObjectId
    if($synced -eq $true){

        try{$localUser= Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties *|Select-Object UserPrincipalName , mailNickName, samaccountname}catch{
            $logs+= [PSCustomObject]@{  UPN = $UPN
                                        CloudMailNickname = $cloudNickname
                                        Status = 'Fail.Could not find on-prem user'
                                        OnPremDN = $OnPremDN
                                        CloudObjID = $CloudObjID

                                        }
            }
    
        $OnPremNickname = $localUser.mailNickname
        $samaccountname= $localUser.samaccountname
        $OnPremDN = $localUser.DistinguishedName
        Write-Host "User number $i in progress"
        if($cloudNickname -ne $OnPremNickname){  
                 
                Write-Host "they dont match for user $UPN Number $i"
           
               Set-aduser -Identity $samaccountname -Replace @{MailNickName = "$cloudNickname"} -Server $server
               $newOnPremNickname = Get-ADUser -Identity $samaccountname -Properties * -Server $server | Select-Object mailNickName 
               if($newOnPremNickname -eq $cloudNickname){
                    Write-host "Success"
                    $logs+= [PSCustomObject]@{ UPN = $UPN
                                        CloudMailNickname = $cloudNickname
                                        Status = 'Success'
                                        OnPremDN = $OnPremDN
                                        CloudObjID = $CloudObjID
                                        }
                        }else{
                             $logs+= [PSCustomObject]@{ UPN = $UPN
                                        CloudMailNickname = $cloudNickname
                                        Status = 'Fail'
                                        OnPremDN = $OnPremDN
                                        CloudObjID = $CloudObjID
                                        }
                            }
                    }
                    }else{
                        $logs+= [PSCustomObject]@{ UPN = $UPN
                                        CloudMailNickname = $cloudNickname
                                        Status = 'Fail.No on-prem users'
                                        OnPremDN = $OnPremDN
                                        CloudObjID = $CloudObjID
                                        }
                                        }
        $i++
<#
    $cloudNickname = $null
    $UPN =$null
    $localUser = $null
    $OnPremNickname = $null
    $samaccountname = $null
    #>

                }
    
