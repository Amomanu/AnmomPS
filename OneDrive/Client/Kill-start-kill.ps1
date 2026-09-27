<#
.SYNOPSIS
    Starts OneDrive once for every profile on the computer and stops it again.
.DESCRIPTION
    Stops OneDrive, waits 10 seconds, starts C:\Users\<profile>\AppData\Local\Microsoft\OneDrive\OneDrive.exe
    for every folder under C:\Users, waits 20 seconds and stops all OneDrive processes again - for example
    so that OneDrive can apply new settings without being left running.
.NOTES
    Note     : the processes start as the account that runs the script. Profiles without OneDrive.exe
               (Public, Default, ...) produce errors that can be ignored.
#>


$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id

Start-Sleep -Seconds 10

$Users=Get-ChildItem -Path C:\Users
foreach ($item in $Users)
    {
    $foltosearch=('C:\Users\'+$item.Name)
    $ODPath= $foltosearch+'\AppData\Local\Microsoft\OneDrive\OneDrive.exe'
    #$ODPath
    Start-Process $ODPath 
    }

Start-Sleep -Seconds 20

$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id
