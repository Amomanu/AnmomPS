<#
.SYNOPSIS
    Adds one account as site collection administrator on every SharePoint Online site, temporarily
    unlocking locked sites.
.DESCRIPTION
    Prompts for the password of $AdminName, connects to SharePoint Online ($AdminURL) and processes every
    site returned by Get-SPOSite -Limit ALL (OneDrive sites are not included). For each site it logs the
    current site collection admins, adds $SPName as site collection admin (Set-SPOUser
    -IsSiteCollectionAdmin) and logs the admins again. Sites with LockState NoAccess are unlocked first and
    locked again afterwards. Everything is logged as text lines to C:\SPOSP\logs.csv (the script creates
    C:\SPOSP).
.NOTES
    Requires : SharePoint Online Management Shell and a SharePoint admin account that can sign in with
               user name + password (Connect-SPOService -Credential does not work with MFA).
    Setup    : set $AdminURL, $AdminName and $SPName (the login name of the account to add).
    Known issue: the "Added Site Collection Admin" check passes whenever the site has any admin, so it is
    not a reliable success indicator - check the "Final Permissions" lines in the log.
#>


$AdminURL = "https://m365x000000-admin.sharepoint.com/"
$AdminName = "admin@M365x000000.onmicrosoft.com" #Test tenant Replace with REAL creds, or ask from terminal
$SPName = "svc-spo@M365x000000.onmicrosoft.com"  
cd C:\
mkdir SPOSP  #Creates folder to store log CSV

cd .\SPOSP

#User Names Password to connect
$Password = Read-host -assecurestring "Enter Password for $AdminName"
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Password
 
#Connect to SharePoint Online
try
    {
        Connect-SPOService -url $AdminURL -credential $Credential
        }
   Catch {
           if($_.Exception.Message.contains("The remote server returned an error: (401) Unauthorized"))
                {write-host -f Red "PermissionsMissiong.Check account permissions"
                Write-Error "terminating" -ErrorAction Stop
          }
            elseif($_.Exception.Message.contains("Could not connect to SharePoint Online"))
                {write-host -f Red "Cant connect to Microsoft Servers. Check internet connectivity"
                Write-Error "terminating" -ErrorAction Stop
          }
        }



 
$Sites = Get-SPOSite -Limit ALL
 
Foreach ($site in $Sites)
{ 
try{ Write-host -f Yellow $site.Title
        If ($site.LockState -contains "NoAccess")
        {
            $UnlockingSite="unlock "+$site.url 
            Set-SPOSite -Identity $site -Lockstate “Unlock”| Out-Null   #Unlock site
            $statelock=(Get-SPOSite -Identity $site).Lockstate
            If ($statelock -contains "Unlock")        #Verifies if the lock was removed succesfully
                {echo "$UnlockingSite was succesfull"| add-content -path "C:\SPOSP\logs.csv" #writes to CSV unlock of the site
                }
              else {echo "$UnlockingSite was NOT succesfull"| add-content -path "C:\SPOSP\logs.csv" #writes to CSV unlock of the site
                 }
            $title=$site.Title
            echo "Initial Permissions on the library $title " | add-content -path "C:\SPOSP\logs.csv" #writes to CSV original permissions of the site
            Get-SPOUser -Site $site.Url -Limit ALL | where { $_.IsSiteAdmin -eq $True} | Select-Object DisplayName | add-content -path "C:\SPOSP\logs.csv" #Gets a list with original admins
            

                try{
        Set-SPOUser -site $Site -LoginName $SPName -IsSiteCollectionAdmin $True | Out-Null  #Add SP account to Site as admin
        }
                catch{}
                $status=Get-SPOUser -Site $site.Url
                if($status.IsSiteAdmin -eq("True")) #Verifies if it was succesfull
                     { $localsite = $site.Url
                     echo "Added Site Collection Admin succesfull for $SPName for: $localsite" | add-content -path "C:\SPOSP\logs.csv"
                }
                  else 
                  {$localsite = $site.Url 
                  echo "Did NOT add Site Collection Admin succesfull for $SPName for: $localsite" | add-content -path "C:\SPOSP\logs.csv"
                  }
            echo "Final Permissions on the library $title " | add-content -path "C:\SPOSP\logs.csv" 
            Get-SPOUser -Site $site.Url -Limit ALL | where { $_.IsSiteAdmin -eq $True} | Select-Object DisplayName | add-content -path "C:\SPOSP\logs.csv"
            Set-SPOSite -Identity $site -Lockstate “NoAccess” | Out-Null
          
            $UnlockingSite="lock "+$site.url 
            $stateoflock=(Get-SPOSite -Identity $site).Lockstate
                If ($stateoflock -contains "NoAccess")    #Verifies if the lock was succesfully applied
                 {echo "$UnlockingSite was succesfull"| add-content -path "C:\SPOSP\logs.csv" #writes to CSV unlock of the site
                }
                 else {
              echo "$UnlockingSite was NOT succesfull"| add-content -path "C:\SPOSP\logs.csv" #writes to CSV unlock of the site
                 }
            $title=$site.Title
           
            
        }
       
      
        else
            {$title=$site.Title
            echo "Initial Permissions on the library $title " | add-content -path "C:\SPOSP\logs.csv" #writes to CSV original permissions of the site
            Get-SPOUser -Site $site.Url -Limit ALL | where { $_.IsSiteAdmin -eq $True} | Select-Object DisplayName | add-content -path "C:\SPOSP\logs.csv" #Gets a list with original admins
            

                try{
        Set-SPOUser -site $Site -LoginName $SPName -IsSiteCollectionAdmin $True | Out-Null  #Add SP account to Site as admin
        }
                catch{}
                $status=Get-SPOUser -Site $site.Url
                if($status.IsSiteAdmin -eq("True")) #Verifies if it was succesfull
                     { $localsite = $site.Url
                     echo "Added Site Collection Admin succesfull for $SPName for: $localsite" | add-content -path "C:\SPOSP\logs.csv"
                }
                  else 
                  {$localsite = $site.Url 
                  echo "Did NOT add Site Collection Admin succesfull for $SPName for: $localsite" | add-content -path "C:\SPOSP\logs.csv"
                  }
            echo "Final Permissions on the library $title " | add-content -path "C:\SPOSP\logs.csv" 
            Get-SPOUser -Site $site.Url -Limit ALL | where { $_.IsSiteAdmin -eq $True} | Select-Object DisplayName | add-content -path "C:\SPOSP\logs.csv"
            
            }
        }

     catch  
               {
                if ($_.Exception.Message.contains("Set-SPOUser : The user does not exist or is not unique"))
                        {
                            $errMessage = "User is not found in the tenant.Check UPN"
                        }
                
                
                Write-host $errMessage -f DarkRed
        
                }
        }
            
    
