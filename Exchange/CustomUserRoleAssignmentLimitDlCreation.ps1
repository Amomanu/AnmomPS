<#
.SYNOPSIS
    Assigns a role assignment policy that stops users from creating or deleting distribution groups
    (they can still manage groups they own).
.DESCRIPTION
    The commented block at the top is the one-time setup: it creates the management role
    "Edit-Existing-DG-Only" (a copy of MyDistributionGroups without New-DistributionGroup and
    Remove-DistributionGroup) and the role assignment policy "NoDgCreation" that contains it. The script
    body then assigns NoDgCreation to mailboxes with Set-Mailbox -RoleAssignmentPolicy, reads each mailbox
    back and prints Success or Fail. Results are kept in $res.
.NOTES
    Requires : ExchangeOnlineManagement module and Connect-ExchangeOnline.
    Setup    : run the commented setup block once first. Get-Mailbox -ResultSize 10 limits the run to
               10 mailboxes (test setting) - change it for a full run.
    Important: a mailbox has only one role assignment policy. NoDgCreation, as created here, contains only
               the Edit-Existing-DG-Only role, so it replaces the mailbox's current policy (e.g. Default
               Role Assignment Policy) and the other end-user roles in it. Add those roles to NoDgCreation
               if users need them.
    Known issues: failures are not collected ("$eror =+" overwrites instead of adding) and the Fail
    message prints $userp (typo) instead of the UPN.
#>


#Connect-ExchangeOnline
$res = $null
$res = @()
$eror = $null
$eror = @()



<# Creaton of Rule to block regular users from creating/deleting dls 
New-ManagementRole -Name "Edit-Existing-DG-Only" -Parent MyDistributionGroups  #to create another subcategorey
Remove-ManagementRoleEntry "Edit-Existing-DG-Only\New-DistributionGroup" #removing the role that allows creation of dl
Remove-ManagementRoleEntry "Edit-Existing-DG-Only\Remove-DistributionGroup" # removing the role that allows deletion of dl
New-RoleAssignmentPolicy -Name "NoDgCreation" -Roles "Edit-Existing-DG-Only" # create new policy with the newly created role.

#>

$Mailboxes = Get-Mailbox -ResultSize 10
foreach($userpn in $Mailboxes.UserPrincipalName){
        $result =$null
        $upn = $null
        $Policy = $null

        Write-Host -Object "Processing user $userpn" -ForegroundColor Yellow -BackgroundColor Black
        Set-Mailbox -Identity $userpn -RoleAssignmentPolicy "NoDgCreation"

        $result = get-Mailbox -Identity $userpn
        $upn = $result.UserPrincipalName
        $Policy = $result.RoleAssignmentPolicy

        $res += [PSCustomObject]@{
           UserPrincipalName = $upn
           Policy = $Policy 
                    }
        If($Policy -eq 'NoDgCreation'){
            Write-Host -Object "Success for user $userpn"-ForegroundColor Green -BackgroundColor Black
            }else{
                $eror =+  [PSCustomObject]@{
                    UserPrincipalName = $upn
                    Policy = $Policy 
                    }
                Write-Host "Fail for user $userp" -ForegroundColor Black -BackgroundColor Red
            }


    }


