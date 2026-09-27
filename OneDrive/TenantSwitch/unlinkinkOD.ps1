<#
.SYNOPSIS
    Unlinks the OneDrive work account for the current user and lists the local OneDrive folders.
.DESCRIPTION
    Force-stops OneDrive, deletes HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace
    and HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1 (the cached OneDrive work account and its
    navigation-pane entry), then lists the folders named "OneDrive*" in every profile under C:\Users,
    taking ownership of a profile folder when access is denied.
.NOTES
    Note     : the folder deletion is commented out (Remove-Item), so the folders are only listed.
               Deleting the NameSpace key removes all Explorer navigation-pane entries of the current
               account, not only OneDrive. Registry changes apply to the account running the script.
#>


$Process=get-process |Where-Object {$_.ProcessName -like "*OneDrive*"}
$ODID=$process.Id
Stop-Process -Id $ODID -Force      #Stops OD



#Remove Hkeys to remove account cache

[switch]$yes="Yes"
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace" -Force -Recurse
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1" -Force -Recurse



#Delete Default OD Location
$accountAdmin=([Security.Principal.WindowsIdentity]::GetCurrent()).Name
$Users=dir C:\Users
foreach ($item in $Users)
    {#$item.Name
       $foltotry=('C:\Users\'+$item.Name)
       try {  
            $folder=dir $foltotry
            foreach($row in $folder)
                {
                    if($row -like "OneDrive*")
                        {$delete=($foltotry+"\"+$row)
                        #$delete
                        $row
                        #Remove-Item $delete -Recurse
                        }
                    }
           }catch{
                if ($_.Exception.Message.contains("denied"))
                    {takeown.exe /f $foltotry 
                    $folder=dir $foltotry
                        }
            
        
        
        }
        Clear-Variable foltotry

        }
