<#
.SYNOPSIS
    Finds enabled users whose primary SMTP address differs from their UPN.
.DESCRIPTION
    Reads all Azure AD users. For each enabled user it gets the Exchange Online mailbox and compares its
    PrimarySmtpAddress with the UserPrincipalName. Mismatches are printed and added to $Report (UPN,
    MailProxy).
.NOTES
    Requires : AzureAD and ExchangeOnlineManagement modules; connect to both first.
    Output   : results stay in $Report - export with $Report | Export-Csv <path> -NoTypeInformation.
    Note     : enabled users without a mailbox produce a Get-EXOMailbox error and are skipped.
#>


# This file will pull all Azure ad users.It will verify each enabled account to strore UPN, followed by ExchangeOnline to get the primaryProxy.Then it will compare.If different, they get writtent to $report, that can be exported to CSV if needed



$AllUsers = Get-AzureADUser -All $true
$Report = $null
$Report = @()
foreach($User in $AllUsers){
       $UserUPN= $null
       $ExoMailbox = $null
       $MBX = $null
        if($user.AccountEnabled -eq "True"){
           $UserUPN = $User.UserPrincipalName
           $ExoMailbox= get-exomailbox -Identity $UserUPN
           $MBX= $ExoMailbox.PrimarySmtpAddress
           }
        if($MBX -ne $null){
            if($MBX -notlike $UserUPN){

            echo ' Proxy is' $MBX 
            echo 'UPN is'$UserUPN
            $Report+= [PSCustomObject]@{ UPN = $UserUPN|Out-string
                                    MailProxy = $MBX|Out-String
                                
                                    }
                                  }
                            }
        
         

    }
