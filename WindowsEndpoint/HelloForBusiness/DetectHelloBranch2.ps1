<#
.SYNOPSIS
    Collects Windows Hello for Business information from a device into a text report.
.DESCRIPTION
    Takes ownership of the Windows Hello container folder
    (C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc) and grants the running account
    Full Control so it can be read. If the folder exists, it writes to C:\temp\HelloFolder\results.csv:
    the computer name, the number of subfolders in Ngc (used as the number of users who set up a PIN),
    the latest Hello for Business event 8203 (full text plus machine, user, time and level) and the
    details of the latest event 5520 (labelled "Last device unlock with MFA details"). Finally it gives
    ownership to the Administrators group and adds a Deny Full Control entry for the running account.
.NOTES
    Requires : administrator rights.
    Note     : the report is a text file even though it is named .csv; the "Extract..." scripts in this
               folder read it by line position.
    WARNING  : it changes the owner and permissions of a system folder used by Windows Hello and leaves a
               Deny entry for the account that ran it (SYSTEM, if deployed that way). Test before rolling
               it out.
#>


$path = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"

$csvpath="C:\temp\HelloFolder"
$csvname="results.csv"
try{mkdir -Path $csvpath
New-Item -Path $csvpath -Name $csvname}
catch{}
$output = $csvpath+'\'+$csvname


$hostname=hostname


$identity=whoami
takeown /f "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc" /r /d Y
$ACL = Get-Acl -Path $path
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Allow")
$ACL.SetAccessRule($Ar)
Set-Acl $path $ACL


$doesPathExist=Test-Path $path    #Test if folder exists

if ($doesPathExist -eq "True")
    {echo " there are folders that exits in the NGC folder for machine" $hostname |add-content -path $output 
     Get-ChildItem -path $path -depth 0 -Force | measure  | Select-Object Count  |add-content -path $output                #Count number of folders (Number of users that have created a PIN on the device)
     $8203=get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-HelloForBusiness/Operational' ; id=8203} -MaxEvents 1 | Out-String | add-content -path $output 
     $8203Details=get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-HelloForBusiness/Operational' ; id=8203} -MaxEvents 1|Select-Object MachineName , UserId , TimeCreated , LevelDisplayName  | Format-List -Property * | Out-String | add-content -path $output 
     echo "Last device unlock with MFA details"| add-content -path $output 
     $5520Details=get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-HelloForBusiness/Operational' ; id=5520} -MaxEvents 1|Select-Object MachineName , UserId , TimeCreated , LevelDisplayName  | Format-List -Property * | Out-String | add-content -path $output 
  
      }
      
takeown /f $path /a
$ACL = Get-Acl -Path $path
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity ,"FullControl","Deny")
$ACL.SetAccessRule($Ar)
Set-Acl $path $ACL




