<#
.SYNOPSIS
    Same as "Enabling ODFOD as admin -nocreds and email.ps1", plus a local log file.
.DESCRIPTION
    Sets FilesOnDemandEnabled = 1 under HKLM:\SOFTWARE\Policies\Microsoft\OneDrive, stops OneDrive,
    starts "OneDrive.exe /update /restart /qn" as the logged-on user through a temporary scheduled task,
    reads the policy value back, emails "success" or "fail" through smtp.office365.com (port 587) and
    writes each step (registry changes, restart, result) to a log file in C:\temp.
.NOTES
    Requires : administrator rights; the sending mailbox needs SMTP AUTH enabled.
    Setup    : set $un, $pw and the -From / -To addresses in the Send-MailMessage line.
    Known issue: the log path is built before $hostname is set, so the log is written to C:\temp\.txt
    instead of C:\temp\<computer name>.txt, and C:\temp is only created after the first write to it.
#>


$path= 'C:\temp\'+$hostname+'.txt'
$null> $path
#Settings
mkdir C:\temp -Force

$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\OneDrive"
$keypath=New-Item -Path $registryPath -Force 
Add-Content -Value $keypath -Path $path
Add-Content -Value "-----------------------" -Path $path
$keyitem=New-ItemProperty -Path $registryPath -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWORD -Force 
Add-Content -Value $keyitem -Path $path
Add-Content -Value "-----------------------" -Path $path
$hostname=hostname

#Stopping OD
Write-Output "Terminating OneDrive"
Add-Content -Value "Terminating OneDrive" -Path $path
Add-Content -Value "-----------------------" -Path $path

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
Add-Content -Value "Starting OD via scheduled task" -Path $path
Add-Content -Value "-----------------------" -Path $path

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


#Writing log to file



Add-Content -Path $path -Value $bod
Add-Content -Value "-----------------------" -Path $path