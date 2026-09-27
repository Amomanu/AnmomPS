<#
.SYNOPSIS
    Removes sensitivity-label encryption from the SharePoint / OneDrive files listed in a CSV.
.DESCRIPTION
    Connects to SharePoint Online ($SiteURL, the admin URL) and, for each file URL in the Link column of
    $csvFile, runs Unlock-SPOSensitivityLabelEncryptedFile with the justification "Administrator removed
    label". Throttling errors (ResourceBudgetExceeded, MSIP API exception) are retried once after 60
    seconds; other known errors are translated to readable messages (archive files are reported as not
    supported). Successes and errors are written to C:\temp\logs.txt, failures also to
    C:\temp\failedlogs.txt (both files are emptied at the start).
.NOTES
    Requires : SharePoint Online Management Shell and SharePoint admin rights. The script also connects
               with PnP PowerShell (Connect-PnPOnline), which it does not otherwise use.
    Setup    : set $csvFile and $SiteURL.
#>


$path= 'C:\temp\logs.txt'
$failedpath='C:\temp\failedlogs.txt'
$null> $path
$null>$failedpath
$csvFile = "C:\temp\treytest.csv"
$table = Import-Csv $csvFile -Delimiter ","
$SiteURL="https://m365x000000-admin.sharepoint.com/"



Connect-PnPOnline -Url $SiteURL 
Connect-SPOService -Url $SiteURL
$startTime=get-date
Add-Content -Value ('Started At' + $startTime) -Path $path
foreach ($row in $table)
{       try{ 
            Unlock-SPOSensitivityLabelEncryptedFile -FileUrl $row.Link -JustificationText "Administrator removed label"
            Add-Content -Value ('UnlockedDataForFile'+$row.Link) -Path $path
            }catch{
                # Convert common exception messages into human understandable form
                if ($_.Exception.Message.contains("ResourceBudgetExceeded"))
                    {Start-Sleep -Seconds 60
                        try{

                            Unlock-SPOSensitivityLabelEncryptedFile -FileUrl $row.Link -JustificationText "Administrator removed label"
                            Add-Content -Value ('UnlockedDataForFile'+$row.Link) -Path $path
                            }catch{
                                    # Convert common exception messages into human understandable form
                                    if ($_.Exception.Message.contains("ResourceBudgetExceeded"))
                                        {Add-Content -Value ('UnlockedDataForFile'+$row.Link+'failed. Throtteling!') -Path $failedpath
                                        $errMessage = ('Throtteling!')
                                        }
                                    }
                     } 
                 elseif($_.Exception.Message.contains("User cannot be found"))           
                        {$errMessage = "User URL not found or permissions missing."
                         Add-Content -Value ('UnlockedDataForFile'+$row.Link+'failed. User URL not found or permissions missing!') -Path $failedpath
                            }  
                 elseif($_.Exception.Message.contains("primaryStream.GetZipStorage"))
                        {$errMessage = ('Can not unencrypt archieves!')
                        Add-Content -Value ('UnlockedDataForFile'+$row.Link+'failed. Can not unencrypt archieves!') -Path $failedpath
                        }
                 elseif($_.Exception.Message.contains("MSIP.AIPFile.SetTags/Commit(fileStorage) failed with APIException"))
                 {Start-Sleep -Seconds 60
                        try{
                            Unlock-SPOSensitivityLabelEncryptedFile -FileUrl $row.Link -JustificationText "Administrator removed label"
                            Add-Content -Value ('UnlockedDataForFile'+$row.Link) -Path $path
                            }catch{
                                    # Convert common exception messages into human understandable form
                                    if ($_.Exception.Message.contains("MSIP.AIPFile.SetTags/Commit(fileStorage) failed with APIException"))
                                        {Add-Content -Value ('UnlockedDataForFile'+$row.Link+'failed. Throtteling!Check/empty  \AppData\Local\Microsoft\MSIP\Logs\MSIPExecutionHost.iplog ') -Path $failedpath
                                        $errMessage = ('Error-throtteling/wrong files in appdata!')
                                        }
                                    }
                     } 
                    else
                        {$errMessage=$_.Exception.Message
                        }
                Add-Content -Value ('Error'+$errMessage +'for file' + $row.Link ) -Path $path    
            }
    
    
}
$finishTime=get-date
Add-Content -Value ('Finished At' + $finishTime) -Path $path