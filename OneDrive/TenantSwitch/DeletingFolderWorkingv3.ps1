<#
.SYNOPSIS
    Resets the OneDrive client on a PC for a tenant switch: backs up the local OneDrive folders, removes
    the old account and folders, and prepares OneDrive for the new tenant.
.DESCRIPTION
    Steps, in order:
      1. Sets FilesOnDemandEnabled = 0 (policy), starts OneDrive for every profile under C:\Users, waits
         and stops it.
      2. For every folder named "OneDrive*" in every profile: takes ownership, grants the running account
         Full Control, clears read-only and copies its content to C:\Users\<profile>\Documents\Old.
      3. Stops OneDrive and deletes, for the account running the script,
         HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace and
         HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1.
      4. Deletes every "OneDrive*" folder in every profile.
      5. Sets OneDrive to start at logon (HKCU Run), sets KFMSilentOptIn ($tenID) and
         FilesOnDemandEnabled = 1, and starts OneDrive for every profile so the user can sign in to the
         new tenant.
.NOTES
    WARNING  : destructive. It deletes all "OneDrive*" folders in all profiles after copying them, and
               deletes the whole Desktop\NameSpace key (all Explorer navigation-pane entries of the
               current account, not only OneDrive). Test on one PC and check the Documents\Old copy.
    Note     : OneDrive is stopped before the copy, so files that are still online-only (not downloaded)
               may not be copied. Registry changes apply only to the account running the script (HKCU);
               the folder backup and deletion apply to all profiles.
    Requires : administrator rights, run in the user's session.
    Setup    : set $tenID to the new tenant ID.
#>


#DISABLE FilesOnDemand
Write-Output "Removing FilesOnDemand"
$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"

New-Item -Path $registryPath -Force | Out-Null

New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 0 -PropertyType DWORD -Force | Out-Null

Start-Sleep -Seconds 10

#Starting OD
Write-Output "Starting OD"

Write-Output "Starting OneDrive and waiting 60s"
$Users=Get-ChildItem -Path C:\Users
foreach ($item in $Users)
    {
    $foltosearch=('C:\Users\'+$item.Name)
    $ODPath= $foltosearch+'\AppData\Local\Microsoft\OneDrive\OneDrive.exe'
    #$ODPath
    Start-Process $ODPath 
    }

Start-Sleep -Seconds 10

#Stopping OD
Write-Output "Terminating OneDrive"

$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id


Start-Sleep -Seconds 10

#Copying OD Folder to old

Write-Output "Copying OD Folder"

$identity=whoami   
$Users=Get-ChildItem -Path C:\Users
foreach ($item in $Users)
    {   $foltotry=('C:\Users\'+$item.Name)
        $foldertoserach= Get-ChildItem -Path $foltotry
        foreach ($row in $foldertoserach)
            {
                if($row.Name -like "OneDrive*")
                    {$move=($foltotry+"\"+$row.name)
                    $foldersource = Get-Item -Path $move
                    $takeown=takeown /a /r /d Y /f $move
                    $ACL = Get-Acl -Path $move
                    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Allow") 
                    $ACL.SetAccessRule($Ar)
                    Set-Acl $move $ACL
                    $foldersource.Attributes =  $foldersource.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly


                    $Destination= ("C:\Users\"+$item.Name+"\Documents\Old")
                    mkdir $Destination
                    $folderdest = Get-Item -Path $Destination
                    $takeownd=takeown /a /r /d Y /f $Destination
                    $ACL = Get-Acl -Path $Destination
                    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Allow") 
                    $ACL.SetAccessRule($Ar)
                    Set-Acl $Destination $ACL
                    $folderdest.Attributes = $folderdest.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
                    
                    Copy-Item -Path ($move+"\*") -Destination $Destination -PassThru -Force -Verbose -Recurse
                    #Remove-Item -Recurse -Path $move -Force
                    }
            }    
    }

Start-Sleep -Seconds 10



#Stopping OD .




Write-Output "Terminating OneDrive"

$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id


Start-Sleep -Seconds 10

#Removing HKeys refereinces to old tenant

Write-Output "Removing old dependencies in Hkeys"

[switch]$yes="Yes"
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace" -Force -Recurse
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1" -Force -Recurse



Start-Sleep -Seconds 10




#Delete Default OD Location

Write-Output "Deleting OD Folder"

$identity=whoami   
$Users=Get-ChildItem -Path C:\Users
foreach ($item in $Users)
    {   $foltotry=('C:\Users\'+$item.Name)
        $foldertoserach= Get-ChildItem -Path $foltotry
        foreach ($row in $foldertoserach)
            {
                if($row.Name -like "OneDrive*")
                    {$move=($foltotry+"\"+$row.name)
                    $foldersource = Get-Item -Path $move
                    $takeown=takeown /a /r /d Y /f $move
                    $ACL = Get-Acl -Path $move
                    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Allow") 
                    $ACL.SetAccessRule($Ar)
                    Set-Acl $move $ACL
                    $foldersource.Attributes =  $foldersource.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
                    Remove-Item -Recurse -Path $move -Force
                    }
            }    
    }



Start-Sleep -Seconds 10



#ADD OD SETTINGS

Write-Output "Adding settings for new instance"
    #AutoStart on login
    Write-Output "1/3"
$computer=hostname
$usernames=(Get-WmiObject -Class win32_process -ComputerName $computer | Where-Object name -Match explorer).getowner().user
foreach ($item in $usernames)
    {$AppDataPath="C:\Users\"+$item+"\AppData\Local\Microsoft\OneDrive\OneDrive.exe /background"
     $AppDataPath
     New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name OneDrive -Value $AppDataPath –Force
     }

Start-Sleep -Seconds 10
     #FolderBackup
     Write-Output "2/3"
     $registryPath = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
$tenID = "00000000-0000-0000-0000-000000000000"     #Update with client ID

New-Item -Path $registryPath -Force | Out-Null

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn" -Value $tenID -PropertyType string -Force

Start-Sleep -Seconds 10
    #FoldersOnDemandEnable
    Write-Output "3/3"
$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"

New-Item -Path $registryPath -Force | Out-Null

New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWORD -Force | Out-Null

#Start OneDrive.User will need to log in.
Write-Output "Starting OneDrive.User will need to authenticate with the new user and go through inital OneDrive setup."
Start-Sleep -Seconds 10

$Users=Get-ChildItem -Path C:\Users
foreach ($item in $Users)
    {
    $foltosearch=('C:\Users\'+$item.Name)
    $ODPath= $foltosearch+'\AppData\Local\Microsoft\OneDrive\OneDrive.exe'
    #$ODPath
    Start-Process $ODPath 
    }


