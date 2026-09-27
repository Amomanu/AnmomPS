<#
.SYNOPSIS
    Lets a standard user enable OneDrive Files On-Demand by writing the policy through local PowerShell
    remoting with admin credentials stored in the script.
.DESCRIPTION
    Uses Invoke-Command against the local computer with the admin account in $username / $password to set
    FilesOnDemandEnabled = 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive. Then, as the current user,
    it stops OneDrive and starts OneDrive.exe for every profile under C:\Users.
.NOTES
    Requires : WinRM (PowerShell remoting) enabled on the computer.
    Setup    : set $username and $password.
    SECURITY : the admin password is stored in clear text in the script - anyone who can read the script
               can use that account.
    Note     : profiles without OneDrive.exe produce errors that can be ignored.
#>


#Settings as admin
$hostname=hostname
$username = "<ADMIN_UPN>"
$password = "<PASSWORD>"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    Invoke-Command -Credential $cred -Computer $hostname -ScriptBlock { $registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"
    New-Item -Path $registryPath -Force 
    New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWORD -Force 
    }
#Stopping OD
Write-Output "Terminating OneDrive"

$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id
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
