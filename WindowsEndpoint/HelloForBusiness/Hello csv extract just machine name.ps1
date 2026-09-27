<#
.SYNOPSIS
    Variant of the Hello report consolidation that only checks whether the Ngc folder exists.
.DESCRIPTION
    Reads every report file in $path. When line 1 of a report contains "there are folders that exits"
    (written by DetectHelloBranch2.ps1 when the Ngc folder exists), it appends the machine name (line 5)
    to logsmachine.csv and the user SID (line 9) to logsSIDuser.csv in $logpath.
.NOTES
    Setup    : set $path (ending with "\") and $logpath.
    Note     : despite its name it also writes the user SID. The parsing depends on fixed line positions.
#>


$path="C:\a\hellocsv\"                                                         #Path of results file to query
$logpath="C:\a\hellocsv\hellousercsv\HelloUsersList\"                                             #Path where it find saves the 2 result files
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
#$checkHelloState=$csv[6] | Out-String      
$checkHelloState=$csv[0] | Out-String                                                  #Picks line with results in CSV
$checkHelloState = $checkHelloState.TrimStart("


A                                                                                                                    
-                                                                                                                    
")
$checkHelloState = $checkHelloState.TrimEnd("

")
Clear-Variable -Name "finalpath"


#if (($checkHelloState -like '*enabled*')-and($checkHelloState -like '*Success*'))                    #checks if hello is enabled (certificate created)
 if ($checkHelloState -like '*there are folders that exits*')  
  {
  #$machinename =$csv[12] | Out-String    
  $machinename =$csv[4] | Out-String                                                             #gets machine name
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

