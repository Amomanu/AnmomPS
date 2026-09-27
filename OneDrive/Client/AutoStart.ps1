<#
.SYNOPSIS
    Makes OneDrive start at logon by adding it to the HKCU Run key.
.DESCRIPTION
    Finds the users that currently have explorer.exe running on this computer and, for each one, writes
    the Run value "OneDrive" = "C:\Users\<user>\AppData\Local\Microsoft\OneDrive\OneDrive.exe /background".
.NOTES
    Note     : the value is written to HKCU of the account that runs the script, not to each user's
               registry - run it in the user's context. With several logged-on users the last one wins.
               Assumes the profile folder name equals the user name and OneDrive is installed per user.
#>


$computer=hostname
$usernames=(Get-WmiObject -Class win32_process -ComputerName $computer | Where-Object name -Match explorer).getowner().user
foreach ($item in $usernames)
    {$AppDataPath="C:\Users\"+$item+"\AppData\Local\Microsoft\OneDrive\OneDrive.exe /background"
     $AppDataPath
     New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name OneDrive -Value $AppDataPath –Force
     }
