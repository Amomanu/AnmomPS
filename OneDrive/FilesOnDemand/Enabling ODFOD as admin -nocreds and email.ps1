<#
.SYNOPSIS
    Enables OneDrive Files On-Demand through policy, restarts OneDrive in the logged-on user's session
    and emails the result.
.DESCRIPTION
    Sets FilesOnDemandEnabled = 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive and stops OneDrive.
    It then starts "OneDrive.exe /update /restart /qn" as the logged-on user through a temporary
    scheduled task (LaunchOneDrive, which is registered, started and removed again), reads the policy
    value back and emails "success" or "fail" "on machine <computer name>" through smtp.office365.com
    (port 587) with the account in the script.
.NOTES
    Requires : administrator rights (for example run from a deployment tool); the sending mailbox needs
               SMTP AUTH enabled.
    Setup    : set $un, $pw and the -From / -To addresses in the Send-MailMessage line.
    Note     : "success" only confirms the registry value, not that OneDrive applied it. Credentials in the
               script can be read by anyone who can read the file.
#>


#Settings

$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWORD -Force | Out-Null
$hostname=hostname

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

powershell -command "$runpath = 'C:\users\' + (Get-WMIObject -class Win32_ComputerSystem | select username).username.Split('\')[-1] + '\appdata\local\Microsoft\OneDrive\OneDrive.exe /update /restart /qn';$action = New-ScheduledTaskAction -Execute $runpath; $trigger = New-ScheduledTaskTrigger -AtLogOn; $principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName); $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal; Register-ScheduledTask LaunchOneDrive -InputObject $task; Start-ScheduledTask -TaskName LaunchOneDrive; Start-Sleep -Seconds 5; Unregister-ScheduledTask -TaskName LaunchOneDrive -Confirm:$false"
$FOD=Get-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled"
if ($FOD.FilesOnDemandEnabled -eq '1')
		{
            $result='success'
                                }
	else
		{$result='fail'
            }


#Sends email
$un = "admin@M365x000000.onmicrosoft.com"
$pw = "<PASSWORD>"
$sp = $pw | ConvertTo-SecureString -AsPlainText -Force
$plainCred = New-Object system.management.automation.pscredential -ArgumentList $un, $sp
$subj= $result + ' on  machine ' + $hostname
$bod= $result + ' on  machine ' + $hostname
Send-MailMessage -SmtpServer smtp.office365.com -Port 587 -UseSsl -From admin@M365x000000.onmicrosoft.com -To admin@M365x000000.onmicrosoft.com -Subject $subj -Body $bod -Credential $plainCred
