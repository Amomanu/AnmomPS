<#
.SYNOPSIS
    Reports the on-prem mailNickname of mailbox users that are synced from AD.
.DESCRIPTION
    Gets up to 3000 Exchange Online mailboxes. For each one it checks in Azure AD whether the user is
    directory-synced and, if so, reads mailNickname from the on-prem AD user with the same UPN. UPN,
    on-prem MailNickname, mailbox type and IsDirsynced are collected in $Reporting - useful to find
    synced users without an on-prem mailNickname.
.NOTES
    Requires : ExchangeOnlineManagement, AzureAD and ActiveDirectory modules; connect to Exchange Online
               and Azure AD first.
    Output   : results stay in $Reporting (nothing is exported).
    Setup    : raise -ResultSize 3000 for larger tenants.
#>


#Connect-ExchangeOnline
#Connect-AzureAD

$mbx = get-mailbox -ResultSize 3000
$Reporting = $null


$Reporting = @()
foreach($mailbox in $mbx){
    $IsDirsync = $null
    $UPN = $null
    $MBXType = $null

    $UPN = $mailbox.UserPrincipalName
    $MBXType = $mailbox.RecipientTypeDetails
    $IsDirsync = (Get-AzureADUser -ObjectId $UPN).DirsyncEnabled
        if($IsDirsync -eq $true){
            $mailnickname =$null
            $OnpremUser = Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties *|Select-Object samAccountName, mailNickName, mail, Name, DistinguishedName, UserPrincipalName 
            $mailnickname = $OnpremUser.mailNickname
            $Reporting+= [PSCustomObject]@{ UPN = $UPN
                                    MailNickname = $mailnickname
                                    MailboxType = $MBXType
                                    IsDirsynced = $IsDirsync
                                    }
            }
    
        
        
        }
