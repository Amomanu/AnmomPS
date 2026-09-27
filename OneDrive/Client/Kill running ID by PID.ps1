<#
.SYNOPSIS
    Stops the running OneDrive process.
.DESCRIPTION
    Finds the processes named "OneDrive" and stops them by process ID.
.NOTES
    Note     : stopping other users' OneDrive processes requires admin rights.
#>


$process=get-process|Where-Object {$_.ProcessName -eq "OneDrive"}
Stop-Process -Id $process.Id
