<#
.SYNOPSIS
    Looks up the most recent sign-in log entry for Azure AD users (test version: first 10 users).
.DESCRIPTION
    Gets the first 10 Azure AD users (-Top 10) and, for each one, queries the Azure AD sign-in logs
    (Get-AzureADAuditSignInLogs filtered on the UPN, -Top 1). The UPN and LastSignInDate (the entry's
    CreatedDateTime) are stored in $res.
.NOTES
    Requires : the legacy AzureADPreview module and Connect-AzureAD.
    Setup    : remove -Top 10 to process all users.
    Output   : results stay in the $res variable (nothing is exported).
    Note     : only sign-ins still within the sign-in log retention period are found.
#>


#Connect-AzureAD


$users = Get-AzureADUser -Top 10
$res = @()


foreach($obj in $users){
    $currentUPN = $obj.UserPrincipalName

    $Z=Get-AzureADAuditSignInLogs -filter "startsWith(userPrincipalName,'$currentUPN')" -Top 1
    $createdTime = $Z.CreatedDateTime
    $UPN = $z.UserPrincipalName

    $res += [PSCustomObject]@{ 
                                     UPN = $UPN
                                     LastSignInDate = $createdTime
                                    
                }

            }