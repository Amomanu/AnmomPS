
<#
.SYNOPSIS
    Sets each user's manager in AD from a CSV that identifies the manager by objectGUID.
.DESCRIPTION
    For each row in $importpath (columns SAM and ManagerDestObjectGUID; DisplayName and Manager are only
    used in the log) it reads the user by sAMAccountName and the manager by objectGUID on $server, then
    sets the user's Manager attribute to the manager's distinguished name. Rows with an empty SAM or
    manager GUID, a user that cannot be read or a manager that cannot be found are appended to the log
    CSV $Outlogpath. Progress is shown as "i out of n".
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $importpath, $server and $Outlogpath.
    Known issues: $ManagerObject is not cleared between rows, so a row with an empty ManagerDestObjectGUID
    gets the previous row's manager. Failures of Set-ADUser itself are not written to the log.
#>


$importpath = "C:\Temp\ManagersSet2\AllusersAndManager.csv"
$server = "server.domain.corp"
$Outlogpath = "C:\Temp\ManagersSet2\logs.csv"
$lenght = @(Get-Content $importpath).Length
$i = 0
$csv = Import-Csv -Path $importpath 


foreach($row in $csv){
    
    $sam = $row.SAM
    $ManagerGuid = $row.ManagerDestObjectGUID
    $_=$null
    if($sam){
        try{$UserADObject = Get-ADUser -Identity $sam -Properties * -Server $server}catch{
        
            $errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                         UserSAM = $sam
		                                 ManagerDisplayName = "Did not reach that step"
                                         errorMessage = "Failed to get user"
                                         error =  $_
		                                }
            $errorlog| Export-Csv -Path $Outlogpath -NoTypeInformation -Append}

    $_ = $null
    if($ManagerGuid){
        try{$ManagerObject = Get-ADUser -Filter {ObjectGUID -eq $ManagerGuid} -Server $server
        }catch{
            $errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                         UserSAM = $sam
		                                 ManagerDisplayName = $row.Manager
                                         errorMessage = "Failed to get Manager"
                                         error =  $_
		                                }
         $errorlog| Export-Csv -Path $Outlogpath -NoTypeInformation -Append
            }
        }else{
            $errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                         UserSAM = $sam
		                                 ManagerDisplayName = $row.Manager
                                         errorMessage = "ManagerFieldGUID IsEmpty"
                                         error =  $_
		                                }
            $errorlog| Export-Csv -Path $Outlogpath -NoTypeInformation -Append

            }

            
     $_ = $null   
     
     if($ManagerObject){   
        $MDN = $ManagerObject.DistinguishedName
        try{Set-ADUser -Identity $sam -Manager $MDN -Server $server
            }catch{$errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                                UserSAM = $sam
		                                        ManagerDisplayName = $row.Manager
                                                errorMessage = "Failed to set Manager"
                                                error =  $_
		                                }
                }
        }else{
            $errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                         UserSAM = $sam
		                                 ManagerDisplayName = $row.Manager
                                         errorMessage = "ManagerObject Is Empty"
                                         error =  $_
		                                }
            $errorlog| Export-Csv -Path $Outlogpath -NoTypeInformation -Append

            }
                
    
    
    
    

    
   
    if($_ -eq $null){
        Write-Host "$i out of $lenght so far" -ForegroundColor DarkCyan
        }else{
            Write-Host "Error at $i of $lenght. UserEmployeeID = $UserEmployeeID"
            }
            $i++
            

    }else{
            $errorlog=[PSCustomObject]@{ UserDisplayName = $row.DisplayName
                                         UserSAM = $sam
		                                 ManagerDisplayName = $row.Manager
                                         errorMessage = "Sam Is Empty"
                                         error =  $_
		                                }
            $errorlog| Export-Csv -Path $Outlogpath -NoTypeInformation -Append

            }

}
