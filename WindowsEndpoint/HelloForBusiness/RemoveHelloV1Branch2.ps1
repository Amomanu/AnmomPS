<#
.SYNOPSIS
    Resets Windows Hello on a device by moving all Hello containers out of the Ngc folder.
.DESCRIPTION
    Takes ownership of C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc, grants the
    running account Full Control, creates Ngc\old and moves the existing Ngc subfolders into it, so users
    on the device have to set up Windows Hello (PIN) again. The folder list before and after is logged to
    C:\temp\AlpineSkiHouse\RemovingHello\logs.csv. Finally ownership goes to the Administrators group and
    a Deny Full Control entry is added for the running account.
.NOTES
    Requires : administrator rights.
    WARNING  : removes the Windows Hello PINs/keys of all users on the device (the old containers are kept
               in Ngc\old); users must enrol again. Leaves a Deny entry for the account that ran it
               (SYSTEM, if deployed that way).
    Note     : the before/after comparison used to log success is not reliable - check the folder.
#>


$path = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"    #Path of certificate folders
$logpath="C:\temp\AlpineSkiHouse\RemovingHello"      #Path where it will save csv
$logname="logs.csv"              #Name of csv
try{
mkdir -Path $logpath -ErrorAction SilentlyContinue    #trying to create log folder
New-Item -Path $logpath  -Name $logname -ErrorAction SilentlyContinue #trying to create log file
}                         
catch{}
$output = $logpath+'\'+$logname
$identity=whoami                         #gets identity of account runnng the script 

#Adds permissions on NGC folder
takeown /f "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc" /r /d Y |add-content -path $output|Out-Null
$ACL = Get-Acl -Path $path 
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Allow") 
$ACL.SetAccessRule($Ar)
Set-Acl $path $ACL |add-content -path $output|Out-Null

cd "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"

$destination=$path+'\old'   #creates path variable
try{
mkdir old   -ErrorAction SilentlyContinue                #creates folder to move files to
$res0=Get-ChildItem -Path $path  -Directory      #initial folder content
echo "Name of folders attempting to move $res0" |add-content -path $output 
#Get-ChildItem -Path $path  -Directory -Force| Move-Item -Destination -$destination -Force 
dir $path | mv -dest $destination  -ErrorAction SilentlyContinue
}
catch{}
$res1=Get-ChildItem -Path $path           #final folder content
if ( $res0 -eq $res1 )                    #checks if folder content is still identical
   {
   echo "Moving folders failed $res1" |add-content -path $output 
   }
  else
    {
   echo "Moving folders succeded $res1" |add-content -path $output 
   }   
   

#Removes permissions on NGC folder
takeown /f $path /a |add-content -path $output|Out-Null
$ACL = Get-Acl -Path $path 
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Deny") 
$ACL.SetAccessRule($Ar) 
Set-Acl $path $ACL |add-content -path $output|Out-Null
echo "Removed ownership of $path $identity" |add-content -path $output
