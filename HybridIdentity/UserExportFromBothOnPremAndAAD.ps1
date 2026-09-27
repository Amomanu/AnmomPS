

<#
.SYNOPSIS
    Exports each listed user's on-prem and Azure AD matching data (ms-DS-ConsistencyGuid vs ImmutableId)
    plus all soft-deleted cloud users.
.DESCRIPTION
    For each sAMAccountName in the sourcename column of $usersfilepath it reads the AD user from $server
    (UPN, mail, ms-DS-ConsistencyGuid and that value converted to the Base64 ImmutableId format) and the
    Azure AD user with the same UPN (ImmutableId, DirSyncEnabled, AccountEnabled, LastDirSyncTime, deleted
    flag). IdMatch shows whether the value calculated from AD equals the cloud ImmutableId. One row per
    user is appended to $exportuserfile. Finally all soft-deleted Azure AD users (UPN, ImmutableId,
    SoftDeletionTimestamp) are exported to the deleted-users CSV.
.NOTES
    Requires : ActiveDirectory, AzureAD and the legacy MSOnline module; connect to Azure AD and MSOnline
               first.
    Setup    : set $server, $usersfilepath, $exportuserfile and the deleted-users path in the last line.
    Note     : $exportuserfile is the input for ActiveDirectory\ADMT-Migration\PostMigrationVerification.ps1.
               It is appended to, so delete it before re-running. Get-MsolUser without -All returns at
               most 500 deleted users. The Deleted column also shows "Not Deleted" when no cloud user is
               found.
#>


function get-azureaduserObject{

     Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $userUPN
            
    )
    $userOnlineobject = Get-AzureADUser -Filter "userPrincipalName eq '$userUPN'"
    $immutable = $userOnlineobject.ImmutableId
    $UserMail= $userOnlineobject.Mail
    $dirsync = $userOnlineobject.DirSyncEnabled
    $lastdirsync = $userOnlineobject.LastDirSyncTime
    $accountEnabled = $userOnlineobject.AccountEnabled
    $deletionTimestamp = $userOnlineobject.DeletionTimestamp
        if($deletionTimestamp -eq $null){
            $deletionTimestamp = "Not Deleted"}else{
                $deletionTimestamp = "user Deleted"
                    }
    $cu = @()

    $cu += [PSCustomObject]@{    Immutableid = $immutable
		                         DirsynEnabled = $dirsync
                                 AccountEnabled = $accountEnabled
                                 LastDirSyncTime =$lastdirsync
                                 Deleted = $deletionTimestamp
                                    }

    return $cu
    
    #return $userOnlineobject | fl
    }


function Get-DeletedUsersO365{

$DeletedUsers= Get-MsolUser -ReturnDeletedUsers
return $DeletedUsers


}


function Get-aduserobject{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $UserSam,
         [Parameter(Mandatory=$true, Position=1)]
         $Serv
            
    )
    $uo = @()
    $Adobject = get-aduser -identity $UserSam -Properties * -Server $serv
    $upn = $Adobject.UserPrincipalName
    #$msds=$Adobject.'ms-ds-consistencyGUID'
    $msds = get-aduser -identity $UserSam -Properties * -Server $serv | Select-Object mS-DS-ConsistencyGuid
    $msds= $msds.'mS-DS-ConsistencyGuid'
    $immutableIDfromOnPrem = [system.convert]::ToBase64String($msds) 
    $mail= $Adobject.mail


    $clouduo = get-azureaduserObject -userUPN $upn
    $ImmutableID = $clouduo.ImmutableID
    $lastdirsynctime= $clouduo.LastDirSyncTime
    $accountEnabled = $clouduo.AccountEnabled
    $deleted = $clouduo.Deleted
    if($immutableIDfromOnPrem -eq $ImmutableID){
        $match = $true
            }else{
            $match = $false

        }

    $uo += [PSCustomObject]@{ UserPrincipalName = $upn
		                   samaccountname = $UserSam
		                   mail =  $mail|Out-String
                           'ms-ds-consistencyGUID' = $msds | Out-String
                           MSDSConvertdToGUID = $immutableIDfromOnPrem#$msds  |Out-String
                           ImmutableIDfromCloud = $ImmutableID
                           IdMatch = $match
                           LastDirSyncTime = $lastdirsynctime
                           AccountEnabled = $accountEnabled
                           Deleted = $deleted



                           }
    return $uo
    #return (get-azureaduserObject $upn) , $msds ,$mail

    #return (get-aduser -identity $UserSam -Properties * | Select-Object  UserPrincipalName, samaccountname,mail,mS-DS-ConsistencyGuid)

}



$server = "fabrikam-dc-01.corp.fabrikam.com"
$usersfilepath = "C:\ADMT\WGB Exports\userfilelist1945.csv"
$usersfile = Import-Csv -Path $usersfilepath 
$exportuserfile = "C:\ADMT\WGB Exports\PostCutover\UsersExportPostcutover.csv"
$deletedUsersExportFile  = "C:\ADMT\WGB Exports\PostCutover\DeletedUsersPostCutover.csv"

foreach($row in $usersfile){
            $Sam = $row.sourcename
            $upn = $row.targetupn
            #$Sam
            #$upn
            Get-ADUserobject -UserSam $sam -Serv $server | Export-Csv -Path $exportuserfile -NoTypeInformation -Append
            }

$deletedUsers = Get-DeletedUsersO365

$deletedUsers | Select-Object  UserPrincipalName , ImmutableId ,SoftDeletionTimestamp  | Export-Csv -Path "C:\ADMT\WGB Exports\PostCutover\DeletedUsersPostCutover.csv"

