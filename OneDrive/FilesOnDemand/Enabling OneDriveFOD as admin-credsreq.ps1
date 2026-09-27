<#
.SYNOPSIS
    Enables OneDrive Files On-Demand through policy and restarts OneDrive as a user whose credentials
    you type in.
.DESCRIPTION
    Sets FilesOnDemandEnabled = 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive, stops OneDrive, asks
    for a user name (DOMAIN\User) and password and starts
    C:\Users\<name>\AppData\Local\Microsoft\OneDrive\OneDrive.exe with those credentials.
.NOTES
    Requires : administrator rights.
    Note     : the password is typed in clear text (Read-Host without -AsSecureString).
    Known issue: the profile path is built from the full input, so "DOMAIN\User" becomes
    C:\Users\DOMAIN\User\... - use only the part after "\".
#>


#Settings

$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWORD -Force | Out-Null

#Stopping OD
Write-Output "Terminating OneDrive"

$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id
Start-Sleep -Seconds 10

#Starting OneDrive

$username = Read-Host "Please enter your username in format Domain\User"
$password = Read-Host "Please enter your password"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    
$foltosearch=('C:\Users\'+$username)
$ODPath= $foltosearch+'\AppData\Local\Microsoft\OneDrive\OneDrive.exe'
start-process $ODPath -Credential $cred