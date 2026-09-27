<#
.SYNOPSIS
    Enables OneDrive Files On-Demand through policy and restarts OneDrive in the logged-on user's
    session (no credentials needed).
.DESCRIPTION
    Sets FilesOnDemandEnabled = 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive, stops OneDrive and
    starts OneDrive.exe as the logged-on user through a temporary scheduled task (LaunchOneDrive), which
    is removed again after it has started.
.NOTES
    Requires : administrator rights.
    Note     : unlike the other versions it starts OneDrive.exe without /update /restart /qn and does
               not check or report the result.
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

#$username = Read-Host "Please enter your username in format Domain\User"
#$password = Read-Host "Please enter your password"
#$secstr = New-Object -TypeName System.Security.SecureString
#$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
#$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    
#$foltosearch=('C:\Users\'+$username)
#$ODPath= $foltosearch+'\AppData\Local\Microsoft\OneDrive\OneDrive.exe'
#start-process $ODPath -Credential $cred

powershell -command "$runpath = 'C:\users\' + (Get-WMIObject -class Win32_ComputerSystem | select username).username.Split('\')[-1] + '\appdata\local\Microsoft\OneDrive\OneDrive.exe';$action = New-ScheduledTaskAction -Execute $runpath; $trigger = New-ScheduledTaskTrigger -AtLogOn; $principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName); $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal; Register-ScheduledTask LaunchOneDrive -InputObject $task; Start-ScheduledTask -TaskName LaunchOneDrive; Start-Sleep -Seconds 5; Unregister-ScheduledTask -TaskName LaunchOneDrive -Confirm:$false"