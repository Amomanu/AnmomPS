<#
.SYNOPSIS
    Exports who else has access to each OneDrive in the tenant.
.DESCRIPTION
    Connects to SharePoint Online if needed and lists all OneDrive sites (URL containing
    "-my.sharepoint.com/personal/"). For each OneDrive it temporarily adds $UserPrincipalName as site
    collection admin, lists the site's users and groups (Get-SPOUser) except the owner and that admin
    account, then removes the admin right again. Writes OneDriveURL, OwnerUPN, MemberName, MemberUPN,
    MemberIsSiteAdmin and MemberIsGroup to $OutputFolderPath\OneDrivePerms_<date>.csv. Errors while
    adding or removing the admin right go to OneDrivePermsErrorsElevating_<date>.TXT and
    OneDrivePermsErrorsDelevating_<date>.TXT.
.NOTES
    Requires : SharePoint Online Management Shell and a SharePoint admin account.
    Setup    : set $SPOAdminSiteURL, $UserPrincipalName and $OutputFolderPath.
    Note     : Get-SPOUser returns the users known to the site, which can include accounts that no longer
               have access. If $UserPrincipalName was already a site admin on a OneDrive, the script
               removes that right at the end. The export uses -NoClobber, so it fails if the file exists.
#>


#___________________________[PARAMETERS]___________________________
 
#Enter the SharePoint Admin URL
$SPOAdminSiteURL = "https://contoso-admin.sharepoint.com/"
 
#Enter your User Principal Name. This will be used to add Site Collection Admin to the OneDrives and will be removed after pulling permissions.
$UserPrincipalName = "admin@contoso.com"
 
#Enter the output folder path. Do not include the last "\"
$OutputFolderPath = "C:\A\Contoso"
 
#__________________________________________________________________
 
#Validate connection to SharePoint Online
Try{
    Write-Host "Validating connection to SharePoint Online.." -ForegroundColor Cyan
    Get-SPOSite -Limit 1 -ErrorAction Stop | Out-Null
    Write-Host "  Connected to SharePoint Online" -ForegroundColor Green
}
Catch{
    Write-Host "  Not connected to SharePoint Online" -ForegroundColor Yellow
    Write-Host "  Establishing connection..." -ForegroundColor Cyan
 
    Connect-SPOService -Url $SPOAdminSiteURL -WarningAction SilentlyContinue | Out-Null
 
    Write-Host "  Connected to SharePoint Online" -ForegroundColor Green
}
 
$OutputLog = [System.Collections.ArrayList]::new() 
$i = 1
$Date = $null
$Date = Get-Date -Format MM.dd.yy

  

$OneDrives = $null
$OneDrives = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/' "       #-my.sharepoint.com/personal/'
 
Foreach($OneDrive in $OneDrives){
    Write-Host "($i/$($OneDrives.Count)) Getting OneDrive permissions for: '$($OneDrive.Owner)'" -ForegroundColor Cyan
    Try{
        Set-SPOUser -Site $OneDrive.Url -LoginName $UserPrincipalName -IsSiteCollectionAdmin $true | Out-Null
    }
    Catch{
        $_ | Out-String| Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsElevating_$Date.TXT" -NoClobber -Append -Force
        $UserPrincipalName|Out-String | Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsElevating_$Date.TXT" -NoClobber -Append -Force
        $OneDrive.Url|Out-String | Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsElevating_$Date.TXT" -NoClobber -Append -Force

    }
 
    $OneDriveUsers = $null
    $OneDriveUsers = Get-SPOUser -Site $OneDrive.Url
 
    Foreach($OneDriveUser in $OneDriveUsers){
        If(($OneDriveUser.LoginName -ne "$($OneDrive.Owner)") -and ($OneDriveUser.LoginName -ne "$UserPrincipalName")){
            $OutputLogRow = $null
            $OutputLogRow = [pscustomobject] @{
                OneDriveURL = $OneDrive.Url
                OwnerUPN = $OneDrive.Owner
                MemberName = $OneDriveUser.DisplayName
                MemberUPN = $OneDriveUser.LoginName
                MemberIsSiteAdmin = $OneDriveUser.IsSiteAdmin
                MemberIsGroup = $OneDriveUser.IsGroup
            }
 
            [void]$OutputLog.Add($OutputLogRow)
        }
    }
    
    Try{
        Set-SPOUser -Site $OneDrive.Url -LoginName $UserPrincipalName -IsSiteCollectionAdmin $false #| Out-Null
    }
    Catch{
        IF($_){
        $_ | Out-String| Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsDelevating_$Date.TXT" -NoClobber -Append -Force
        $UserPrincipalName|Out-String | Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsDelevating_$Date.TXT" -NoClobber -Append -Force
        $OneDrive.Url|Out-String | Out-File -FilePath "$OutputFolderPath\OneDrivePermsErrorsDelevating_$Date.TXT" -NoClobber -Append -Force
        }
        $_ = $null
     }

    
    $i++
}
 


Write-Host "Exporting output log to '$OutputFolderPath\OneDrivePerms_$Date.csv'"
$OutputLog | Export-Csv -Path "$OutputFolderPath\OneDrivePerms_$Date.csv" -NoTypeInformation -NoClobber




