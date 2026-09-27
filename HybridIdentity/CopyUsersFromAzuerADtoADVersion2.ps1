
<#
.SYNOPSIS
    Function library that creates on-prem AD accounts for existing cloud-only users and hard-matches
    them to the cloud users for Azure AD Connect.
.DESCRIPTION
    The script only defines functions; nothing runs until you call ReadFromCSV. For each cloud user
    (ObjectId column of the CSV), UserCopyFunction:
      - reads the Azure AD user and its Exchange Online mailbox;
      - takes the sAMAccountName from mailbox CustomAttribute11 and builds the UPN from the part of
        CustomAttribute12 before "@" plus the @lucernepublishing.com suffix;
      - checks for existing AD accounts with the same sAMAccountName, UPN or display name, otherwise
        creates the account (New-ADUser) in OU $Path on domain controller $dc;
      - copies department, job title, state, employeeId and mail (mail is also added as primary SMTP
        proxy address);
      - sets a random password, enables the account and appends sAMAccountName, password, current and
        former email to $passexportpath;
      - copies mailbox CustomAttribute10-14 to extensionAttribute10-14;
      - sets ms-DS-ConsistencyGuid to the new account's objectGUID and the cloud user's ImmutableId to
        the same GUID (Base64), so Azure AD Connect matches the new AD account to the existing cloud user.
    Steps are logged to C:\Temp\logs.csv.
.NOTES
    Requires : ActiveDirectory, AzureAD and ExchangeOnlineManagement modules; connect to Azure AD and
               Exchange Online first.
    Usage    : set $CSVPath, $passexportpath, $Path (target OU DN) and $dc (domain controller) at the end
               of the script, dot-source it (. .\CopyUsersFromAzuerADtoADVersion2.ps1) and run:
               ReadFromCSV -CSVPath $CSVPath -dcserver $dc -Path $Path -PassExportPath $passexportpath
    SECURITY : the generated passwords are written in plain text to $passexportpath - protect that file
               and delete it after use.
#>


Function BuildLogs{

Param
    (
         [Parameter(Mandatory=$false, Position=0)]
         $Operation ,
         [Parameter(Mandatory=$false, Position=1)]
         $OperationStatus,
         [Parameter(Mandatory=$false, Position=2)]
         $Error,
         [Parameter(Mandatory=$false, Position=4)]
         $UserDisplayName,
         [Parameter(Mandatory=$false, Position=5)]
         $UserUPN,
         [Parameter(Mandatory=$false, Position=6)]
         $sam,
         [Parameter(Mandatory=$false, Position=7)]
         $userOnlineObjectID,
         [Parameter(Mandatory=$false, Position=8)]
         $userOnPremGUID,
         [Parameter(Mandatory=$false, Position=9)]
         $userImmutable,
         [Parameter(Mandatory=$false, Position=10)]
         $userMsdsconsistencyGuid 



           )

$row = [pscustomobject]@{
            Operation = $Operation
            OperationStatus = $OperationStatus
            Error = $Error
            userDisplayName = $userDisplayName
            userUPN = $userUPN
            sam = $usersam
            userOnlineObjectID = $userOnlineObjectID
            userOnPremGUID = $userOnPremGUID
            userImmutable = $userImmutable
            userMsdsconsistencyGuid = $userConsistencyGUID
        }
    
    $row | Export-Csv -Path "C:\Temp\logs.csv" -NoTypeInformation -Append
}


function Get-AzureADUserObjectList{
 try{$AllUsers = Get-AzureADUser -All $true}catch{
    BuildLogs -Operation "Getting AzureAD Object List" -OperationStatus "Fail" -Error $_ 
    }
 $AllUsersObjID = $AllUsers.ObjectID
 BuildLogs -Operation "Getting AzureAD Object List" -OperationStatus "Success"
 return $AllUsersObjID
 
 }


function Get-OnlineUser{
 Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $ObjectId

           )
    try{
        $Obj =  Get-AzureADUser -ObjectId $ObjectId
        }catch{
            BuildLogs -Operation "Getting Online User" -OperationStatus "Failed" -Error $_
            }
    
    BuildLogs -Operation "Getting Online User" -OperationStatus "Success" -UserDisplayName $obj.DisplayName -UserUPN $Obj.UserPrincipalName -userOnlineObjectID $Obj.ObjectID

    return $Obj



}

function GetADObject{


Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $SamAccountName ,
         [Parameter(Mandatory=$true, Position=1)]
         $DCServer

           )
try{
    $ADobject= Get-ADUser -Identity $SamAccountName -Server $DCServer -Properties * 
    }catch{
BuildLogs -Operation "Getting AD Onpremise User" -OperationStatus "Failed" -Error $_
return "Failed"
            }


BuildLogs -Operation "Getting AD Onpremise User" -OperationStatus "Success" -sam $SamAccountName -userOnPremGUID $ADobject.ObjectGUID -UserUPN $ADobject.UserPrincipalName -UserDisplayName $ADobject.DisplayName 
        
return $ADobject


}

function New-TargetOnPremUser{

Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $CloudMailbox ,
         [Parameter(Mandatory=$true, Position=1)]
         $CloudObject,
         [Parameter(Mandatory=$true, Position=2)]
         $SamName,
         [Parameter(Mandatory=$true, Position=3)]
         $OuPath,
         [Parameter(Mandatory=$true, Position=4)]
         $DCServer
           )

$_=$null
$UPNunformatted = $CloudMailbox.CustomAttribute12
$UPNunformatted = $UPNunformatted -split('@')
$UPN = $UPNunformatted[0]+'@lucernepublishing.com'       #UPN gets suffix appended
$DisplayName = $CloudObject.DisplayName
$NoSpaceDisplayName = $DisplayName.Trim()

$PreviousExistingAccount = $null

try{$PreviousExistingAccount = Get-ADUser -Identity $SamName}catch{<#$_#>}
If($PreviousExistingAccount -ne $null)
    {BuildLogs -Operation "Create User" -OperationStatus "Fail" -Error "SAM:User with $SamName already exists. $_" -sam $SamName -UserUPN $UserPrincipalName
    return "Failed to create user samaccountname $SamName. SAM Duplicate."
    }
$PreviousExistingAccount = $null

$_=$null

try{$PreviousExistingAccount = Get-ADUser -Filter "userPrincipalName -like $UPN" }catch{<#$_#>}   
If($PreviousExistingAccount -ne $null)
    {BuildLogs -Operation "Create User" -OperationStatus "Fail" -Error "UPN:User with $UPN already exists.$_" -sam $SamName -UserUPN $UPN
    return "Failed to create user samaccountname $SamName. UPN Duplicate."
    }


$PreviousExistingAccount = $null
try{$PreviousExistingAccount = Get-ADUser -Filter "DisplayName -like $NoSpaceDisplayName" }catch{<#$_#>}        #based on displyName
if($PreviousExistingAccount -ne $null){
    BuildLogs -Operation "Create User" -OperationStatus "Fail" -Error "DN:User with $DisplayName already exists.$_" -sam $SamName -UserUPN $UPN
    return "Failed to create user samaccountname $SamName. DN Duplicate."
    }
    


$_=$null
Try{New-ADUser -UserPrincipalName $UPN -DisplayName $DisplayName -SamAccountName $SamName -Path $OuPath  -Name $DisplayName -Server $DCServer 
    }catch{
        BuildLogs -Operation "Create User" -OperationStatus "Fail" -Error $_ -sam $SamName -UserUPN $UPN
        return "Failed for $sam"
        }

Start-Sleep -Milliseconds 500

if ($_ -eq $null){
            try{
                $var = Get-ADUser -Identity $SamName -Server $DCServer -Properties *}catch{
                                                                            }
                BuildLogs -Operation "Create User" -OperationStatus "Success" -UserDisplayName $var.DisplayName -UserUPN $var.UserPrincipalName
                
                return "Success creating new user $SamName"
                }
             


}

function Set-password {

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $SamName,
         [Parameter(Mandatory=$true, Position=1)]
         $OutPassPath,
         [Parameter(Mandatory=$true, Position=2)]
         $DCServer,
         [Parameter(Mandatory=$true, Position=3)]
         $eMail,
         [Parameter(Mandatory=$true, Position=4)]
         $OldEmail

           )
$passhash = @()
$pass = -join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})   #Generates 15 char pass
$pass += $pass+'123'+'!!!'   #Adds special signs and digits to bypass gpo policy against simple passwords
try{Set-ADAccountPassword -Identity $SamName -NewPassword (ConvertTo-SecureString -AsPlainText $pass -Force) -Reset -Server $DCServer -ErrorAction Stop
     $passhash=[PSCustomObject]@{ sam = $SamName
		                          password = $pass
                                  CurrentEmail = $eMail
                                  FormerEmail = $OldEmail
		                          }
    $passhash | Export-Csv -Path $OutPassPath -NoTypeInformation -Append
    Enable-ADAccount -Identity $SamName
    
    Return "success resetting the password for $SamName to $pass "

    }catch{return "failed resetting the password for $SamName"
    }    


}

function WriteObjectGuidToExtension{

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $SamName,
         [Parameter(Mandatory=$true, Position=1)]
         $DCServer,
         [Parameter(Mandatory=$true, Position=2)]
         $CloudObject,
         [Parameter(Mandatory=$true, Position=3)]
         $mailbox
           )


$ObjectId = $CloudObject.ObjectID
$extensionattribute10 = $mailbox.CustomAttribute10
$extensionattribute11 = $mailbox.CustomAttribute11
$extensionattribute12 = $mailbox.CustomAttribute12
$extensionattribute13 = $mailbox.CustomAttribute13
$extensionattribute14 = $mailbox.CustomAttribute14


try{Set-ADUser -Identity $SamName -Add @{extensionAttribute10 = $extensionattribute10} -Server $DCServer}catch{
       BuildLogs -Operation "Setting ExtensionAttribute10" -OperationStatus "Failed" -Error $_ -UserUPN $CloudObject.UserPrincipalName 
       write-host " Failed on writing extensionattribute10 for user $($CloudObject.UserPrincipalName)" -ForegroundColor Red 
       }

try{Set-ADUser -Identity $SamName -Add @{extensionAttribute11 = $extensionattribute11} -Server $DCServer}catch{
       BuildLogs -Operation "Setting ExtensionAttribute11" -OperationStatus "Failed" -Error $_ -UserUPN $CloudObject.UserPrincipalName 
       write-host " Failed on writing extensionattribute11 for user $($CloudObject.UserPrincipalName)" -ForegroundColor Red 
       }

try{Set-ADUser -Identity $SamName -Add @{extensionAttribute12 = $extensionattribute12} -Server $DCServer}catch{
       BuildLogs -Operation "Setting ExtensionAttribute12" -OperationStatus "Failed" -Error $_ -UserUPN $CloudObject.UserPrincipalName 
       write-host " Failed on writing extensionattribute12 for user $($CloudObject.UserPrincipalName)" -ForegroundColor Red 
       }

try{Set-ADUser -Identity $SamName -Add @{extensionAttribute13 = $extensionattribute13} -Server $DCServer}catch{
       BuildLogs -Operation "Setting ExtensionAttribute13" -OperationStatus "Failed" -Error $_ -UserUPN $CloudObject.UserPrincipalName 
       write-host " Failed on writing extensionattribute13 for user $($CloudObject.UserPrincipalName)" -ForegroundColor Red 
       }
try{Set-ADUser -Identity $SamName -Add @{extensionAttribute14 = $extensionattribute14} -Server $DCServer}catch{
       BuildLogs -Operation "Setting ExtensionAttribute14" -OperationStatus "Failed" -Error $_ -UserUPN $CloudObject.UserPrincipalName 
       write-host " Failed on writing extensionattribute14 for user $($CloudObject.UserPrincipalName)" -ForegroundColor Red 
       }


<#try{Set-ADUser -Identity $SamName -Add @{extensionAttribute0 = $ObjectId} -Server $DCServer
    }catch{$error = $_}
$verif = (Get-ADUser -Identity $SamName -Properties extensionattribute0).extensionattribute0
if($verif -like $ObjectId){
    BuildLogs -Operation "write CloudObjectID to OnPremise EA0" -OperationStatus "Success" -sam $SamName -userOnlineObjectID $CloudObject.ObjectId -UserUPN $CloudObject.UserPrincipalName
    return "Succesfully wrote the CloudObjectID as Extension attribute0 for $SamName "
        }else{
            BuildLogs -Operation "write CloudObjectID to OnPremise EA0" -OperationStatus "Failed" -sam $SamName -UserUPN $CloudObject.UserPrincipalName
            return "Failed to write the CloudObjectID as Extension attribute0 for $SamName "
            }
            #>

}


function WriteMsdsFromOnPremObjGUID{

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $SamName,
         [Parameter(Mandatory=$true, Position=1)]
         $DCServer,
         [Parameter(Mandatory=$true, Position=2)]
         $OnPremObjectId
           )

$_ = $null

[guid]$ADMSDSConsistencyguid = $OnPremObjectId.ToString()
try{Set-ADUser -Identity $SamName -replace @{'ms-ds-consistencyguid' = $ADMSDSConsistencyguid} -Server $DCServer
    }catch{$error = $_}


$verif = (Get-ADUser -Identity $SamName -Properties 'ms-ds-consistencyguid').'ms-ds-consistencyguid'
if([guid]$verif -like $ADMSDSConsistencyguid){
    BuildLogs -Operation "Wrote MSDSConsistencyGuid" -OperationStatus "Success" -sam $SamName -userOnPremGUID $OnPremObjectId -userMsdsconsistencyGuid $verif
    return "Succesfully wrote the ms-ds-consistencyguid for $SamName , $ExtensionValue"
        }else{
            BuildLogs -Operation "Wrote MSDSConsistencyGuid" -OperationStatus "Failed" -Error $error -sam $SamName -userOnPremGUID $OnPremObjectId
            return "Failed to write the ms-ds-consistencyguid for $SamName , $ExtensionValue"
            }

}



function WriteImmutable{

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $CloudObject,
         [Parameter(Mandatory=$true, Position=1)]
         $OnpremiseObjGUID,
         [Parameter(Mandatory=$true, Position=2)]
         $SamAccountname
           )
$CloudObjectId=$CloudObject.ObjectID
$verif = $null
$_ = $null
$immutable = [Convert]::ToBase64String([guid]::New($OnpremiseObjGUID).ToByteArray())
try{Set-AzureADUser -ObjectId $CloudObjectId -ImmutableId $immutable}catch{$error = $_}
Start-Sleep -Milliseconds 500
$verif = (Get-AzureADUser -ObjectId $CloudObjectId).ImmutableId 
if($verif -like $immutable){BuildLogs -Operation "Writing Immutable to cloud user $SamAccountname" -OperationStatus "Success" -sam $SamAccountname -userOnlineObjectID $CloudObjectId -userOnPremGUID $OnpremiseObjGUID -userImmutable $verif -UserUPN $CloudObject.UserPrincipalName
                            Return "Success on writing immutable for $SamAccountname"
                            }else{BuildLogs -Operation "Writing Immutable to cloud user $SamAccountname" -OperationStatus "Failed" -Error $error -sam $SamAccountname -userOnlineObjectID $CloudObjectId -userOnPremGUID $OnpremiseObjGUID -UserUPN $CloudObject.UserPrincipalName
                                  Return "Failed on writing immutable for $SamAccountname"
                                  }

}



function GetOnlineMailboxAttributes{
    Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $CloudObject
         )
    $_= $null
    if($CloudObject -eq $null){
        BuildLogs -Operation "Getting Mailbox details" -OperationStatus "Failed" -UserDisplayName $CloudObject.displayname -UserUPN $CloudObject.UserPrincipalName -userOnlineObjectID $CloudObject.ObjectId
            }

try{$mailbox = Get-Mailbox -Identity $CloudObject.Objectid
    }catch{}

    if($_ -eq $null){
        BuildLogs -Operation "Getting Mailbox details" -OperationStatus "Success" -UserDisplayName $CloudObject.displayname -UserUPN $CloudObject.UserPrincipalName -userOnlineObjectID $CloudObject.ObjectId
        
        Return $mailbox
        }else{
            BuildLogs -Operation "Getting Mailbox details" -OperationStatus "Failed" -Error $_ -UserDisplayName $CloudObject.displayname -UserUPN $CloudObject.UserPrincipalName -userOnlineObjectID $CloudObject.ObjectId
            }




}

    



function UserCopyFunction{
Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $CloudObjectId,
         [Parameter(Mandatory=$true, Position=1)]
         $DcServer,
         [Parameter(Mandatory=$true, Position=2)]
         $Path,
         [Parameter(Mandatory=$true, Position=3)]
         $PassexportPath
           )

 $UserToBeCopied = Get-OnlineUser $CloudObjectId    
 if($UserToBeCopied){
 $UserMailbox = GetOnlineMailboxAttributes $UserToBeCopied
 if($UserMailbox){
     
     $DisplayName = $UserToBeCopied.DisplayName
     $samfinal =  $UserMailbox.CustomAttribute11  
     try{$samfinal = $samfinal.Trim()}catch{}
     
     $OldEmail = $UserMailbox.CustomAttribute12
     if($samfinal){             
                                                 
     $NewAdUserStatus = New-TargetOnPremUser -CloudMailbox $UserMailbox -CloudObject $UserToBeCopied -SamName $samfinal -OuPath $Path -DCServer $DcServer
     if($NewAdUserStatus -like "*Success*"){
     $NewAdUserStatus


     $OnpremiseObject = GetADObject -SamAccountName $samfinal -DCServer $DcServer
     $mail=$UserToBeCopied.mail
     Copy-Attributes -CloudObject $UserToBeCopied -OnPremiseObject $OnpremiseObject

     Set-password -SamName $samfinal -DCServer $DcServer -OutPassPath $passexportpath -eMail $mail -OldEmail $OldEmail

     WriteObjectGuidToExtension -SamName $samfinal -DCServer $DcServer -CloudObject $UserToBeCopied -mailbox $UserMailbox

     $OnPremiseObjectID = $OnpremiseObject.ObjectGUID

     [guid]$ADMSDSConsistencyguid = $OnPremiseObjectID.ToString()
        WriteMsdsFromOnPremObjGUID -SamName $samfinal -DCServer $dc -OnPremObjectId $OnPremiseObjectID

     WriteImmutable -CloudObject $UserToBeCopied -OnpremiseObjGUID $OnPremiseObjectID -SamAccountname $samfinal
     }else{Write-Host -ForegroundColor Red "Duplicate User"}
    }else{Write-Host -ForegroundColor Red "sam empty"}
  }else{Write-Host -ForegroundColor Red "No mailbox"}
 }else{Write-Host -ForegroundColor Red "No online accunt"}

}



function Copy-Attributes{    

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $CloudObject,
         [Parameter(Mandatory=$true, Position=1)]
         $OnPremiseObject
           )
          
         $department = $null
         $company = $null
         $mail = $null
         $state = $null


         $department = $CloudObject.department | Out-String
           if($department){ try{
                Set-ADUser -Identity $OnPremiseObject.SamAccountName -Department $department}catch{
                                                                                                   BuildLogs -Operation "writing Department" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }
                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing Department" -OperationStatus "Failed" -Error "Department attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName
                                                                                                    }
          <#$company = $CloudObject.CompanyName                                                                                               

          if($company){ try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName -Company $company
                }   catch{
                                                                                                   BuildLogs -Operation "writing Company" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }
                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing Company" -OperationStatus "Failed" -Error "Company attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName
                                                                                                    }#>
                                                                        
         $jobTitle = $CloudObject.JobTitle

         if($jobTitle){
           try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName  -Title $jobTitle
                }   catch{
                                                                                                   BuildLogs -Operation "writing Title" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }  
                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing jobtitle" -OperationStatus "Failed" -Error "JobTitle attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName 
                                                                                                    }
         
         $state = $CloudObject.State
         
         if($state){
           try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName  -State $state
                }   catch{
                                                                                                   BuildLogs -Operation "writing State" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }  
                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing State" -OperationStatus "Failed" -Error "State attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName
                                                                                                    }
                                                     
                                                     
        
        
        $employID = $CloudObject.ExtensionProperty.employeeId
        if($employID){
           try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName  -EmployeeID $employID
                }   catch{
                                                                                                   BuildLogs -Operation "writing employeeID" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }  
                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing employeeID" -OperationStatus "Failed" -Error "State attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName
                                                                                                    }
                                                     
        
        
                                                               
         
                                                                                                                                                                                            
        $mail = $CloudObject.mail
        if($mail){
            try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName  -EmailAddress $mail
                }   catch{
                                                                                                   BuildLogs -Operation "writing mail" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }  

             try{
                 Set-ADUser -Identity $OnPremiseObject.SamAccountName  -Add @{proxyAddresses= "SMTP:$mail"}
                }   catch{
                                                                                                   BuildLogs -Operation "writing proxy" -OperationStatus "Failed" -Error $_ -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName      
                                                                                                   }  

                                                                                                   }else{
                                                                                                    BuildLogs -Operation "Writing mail/proxy" -OperationStatus "Failed" -Error "Mail attribute is empty" -UserUPN $OnPremiseObject.UserPrincipalName -UserDisplayName $OnPremiseObject.DisplayName
                                                                                                    }
          if($_ -ne $null){return $_}                                                        


}


function ReadFromCSV{

Param
    (    [Parameter(Mandatory=$true, Position=0)]
         $CSVPath,
         [Parameter(Mandatory=$true, Position=1)]
         $dcserver,
         [Parameter(Mandatory=$true, Position=2)]
         $Path,
         [Parameter(Mandatory=$true, Position=3)]
         $PassExportPath
           )

$CSV = import-csv -Path $CSVPath
foreach($row in $CSV){
    $objectIdfromCSV = $csv.ObjectId
    UserCopyFunction -CloudObjectId $objectIdfromCSV -DcServer $dcserver -Path $Path -PassexportPath $PassExportPath
    

}
}



$CSVPath = "C:\Temp\run1.csv"     
$passexportpath = "C:\Temp\passexport.csv"
$Path = "#"
$dc = "#"
