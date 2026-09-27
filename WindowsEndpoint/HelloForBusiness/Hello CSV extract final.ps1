<#
.SYNOPSIS
    Consolidates many Hello reports: lists the machine names and user SIDs where Windows Hello for
    Business is enabled.
.DESCRIPTION
    Reads every report file in $path (reports from DetectHelloBranch2.ps1, one per device). When line 7 of
    a report contains both "enabled" and "Success", it appends the machine name (line 13) to
    logsmachine.csv and the user SID (line 9) to logsSIDuser.csv in $logpath.
.NOTES
    Setup    : set $path (folder with the collected reports, ending with "\") and $logpath.
    Note     : the parsing depends on fixed line positions and on the exact event text in the reports.
#>


$path="C:\temp\HelloFolder\test files\"                                                         #Path of results file to query
$logpath="C:\temp\HelloFolder\AlpineSkiHouse\HelloUsersList\"                                             #Path where it find saves the 2 result files
$logsiduser="logsSIDuser.csv"                                                                   #Name of csv
$logmachine="logsmachine.csv"                                                                   #Name of csv
$outputuser = $logpath+'\'+$logsiduser
$outputmachine = $logpath+'\'+$logmachine
$i='0'

try{
mkdir -Path $logpath -ErrorAction SilentlyContinue                                       #trying to create log folder
New-Item -Path $logpath  -Name $logsiduser  -ErrorAction SilentlyContinue                #trying to create log file-SIDUSER
Add-Content -Path $outputuser  -Value '"UserSID"'
New-Item -Path $logpath  -Name $logmachine  -ErrorAction SilentlyContinue                #trying to create log file-MachineName
Add-Content -Path $outputmachine  -Value '"MachineName"'
}                         
catch{}


#Exports necessary filed from CSV to see if Hello is enabled
$children=Get-ChildItem -path $path -depth 0 -Force 
foreach ($row in $children)
{
$finalpath=$path+$row                                                                    #Builds each csv path individually
$csv=import-csv -Path $finalpath -Header A                                               #Imports each csv
$checkHelloState=$csv[6] | Out-String                                                    #Picks line with results in CSV
$checkHelloState = $checkHelloState.TrimStart("


A                                                                                                                    
-                                                                                                                    
")
$checkHelloState = $checkHelloState.TrimEnd("

")
Clear-Variable -Name "finalpath"


if (($checkHelloState -like '*enabled*')-and($checkHelloState -like '*Success*'))                    #checks if hello is enabled (certificate created)
  {
  $machinename =$csv[12] | Out-String                                                                #gets machine name
  $machinename = $machinename.TrimStart("

A                                                                                                                    
-                                                                                                                    
MachineName      : ")
$machinename = $machinename.TrimEnd("

                                                                                                                     
                                                                                                                     
 ")|add-content -path $outputmachine
  $userSID = $csv[8] | Out-String                                                                    #gets user SID
  $userSID = $userSID.TrimStart("

A                                                                                                                    
-                                                                                                                    
UserId           : ")
$userSID = $userSID.TrimEnd("

                                                                                                                     
                                                                                                                     
 ")|add-content -path $outputuser

 }

 }

