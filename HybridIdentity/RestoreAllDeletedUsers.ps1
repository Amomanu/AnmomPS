<#
.SYNOPSIS
    Restores all soft-deleted users from the Azure AD recycle bin.
.DESCRIPTION
    Gets the deleted users with Get-MsolUser -ReturnDeletedUsers, restores each one with
    Restore-AzureADMSDeletedDirectoryObject and appends "<UPN> has been restored from deleted" to $OutPath.
.NOTES
    WARNING  : restores every deleted user, not a selection.
    Requires : the legacy MSOnline and AzureAD modules (Connect-MsolService and Connect-AzureAD).
    Setup    : set $OutPath.
    Note     : Get-MsolUser without -All returns at most 500 users.
#>


$OutPath="C:\Fabrikam\Restoredusers.csv"
#connect-azuread
#Connect-MsolService
$deleted=(Get-MsolUser -ReturnDeletedUsers).ObjectId
foreach ($item in $deleted)
    {
    Restore-AzureADMSDeletedDirectoryObject -Id $item
    $restoredUser=(Get-AzureADUser -ObjectId $item).UserPrincipalName+" has been restored from deleted"
    #$restoredUser
    $restoredUser |Out-File $OutPath -Append

     }
Clear-Variable -Name deleted
