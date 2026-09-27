<#
.SYNOPSIS
    After cutover, checks each user from the post-cutover export against the current AD and Azure AD
    values and flags users that were not migrated correctly.
.DESCRIPTION
    Reads the post-cutover export created by HybridIdentity\UserExportFromBothOnPremAndAAD.ps1
    (UsersExportPostcutover.csv; columns samaccountname, UserPrincipalName, mail, ms-ds-consistencyGUID,
    ImmutableIDfromCloud). For each user:
      - on-prem check: ms-DS-ConsistencyGuid, UPN and mail still match the export;
      - cloud check: the user is not flagged as deleted (see the known issue), the ImmutableId calculated
        from the AD ms-DS-ConsistencyGuid matches the exported cloud ImmutableId, and the cloud mail and
        UPN match.
    Users that fail either check are printed in red. The per-user results (UPN match, ImmutableId
    match, deleted flag and the check results) are written to $exportResultPath.
.NOTES
    Requires : ActiveDirectory and AzureAD modules (run Connect-AzureAD first).
    Setup    : set the Import-Csv path and $exportResultPath.
    Note     : in the output, CompleteSuccess holds the cloud-check result and CloudCompleteSuccess holds
               the overall result. $timetolookbehind and $minus4hours are not used.
    Known issue: the deleted check never detects a deleted user - Get-AzureADUser does not return
    soft-deleted users, so IsUserDeleted is always False. A deleted user is still printed in red, but only
    because its other cloud checks (such as the UPN match) fail.
#>


function Get-UserAD{
 Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $userSAM
            
    )
    return Get-ADUser -Identity $userSAM -Properties *
    }




function Get-UserAzureAD{
 Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $userUPN
            
    )
    return Get-AzureADUser -ObjectId $userUPN
    }


function ConvertGUIDtoImmutable ($valuetoconvert){
        $guid = [GUID]$valuetoconvert
        $bytearray = $guid.tobytearray() 
        $immutableID = [system.convert]::ToBase64String($bytearray) 
        return $immutableID
    }



$timetolookbehind = '4'
$a = import-csv -Path "C:\ADMT\WGB Exports\PostCutover\UsersExportPostcutover.csv"
$today = Get-Date
$minus4hours= $today.AddHours('4')
$result = @()

foreach($row in $a){
        $c = Get-UserAD $row.samaccountname     #AD User All attributes
        $f= Get-UserAzureAD $row.UserPrincipalName #Azure AD User All Attributes
        $b = $c.'mS-DS-ConsistencyGuid' | Out-String #AD User MS-DS-ConsistencyGUID
        $d = $c.UserPrincipalName #AD User UPN
        $e = $c.mail|Out-String #AD User mail
        $g = $f.DeletionTimestamp #AzureADDeletionTimestamps
        $h = $f.ImmutableId #AzureAD Immutable
        $i = (Get-ADUser -Identity $row.samaccountname -Properties * | Select-Object mS-DS-ConsistencyGuid).'mS-DS-ConsistencyGuid' #gets MS-DS-ConsistencyGUID only
        $j=ConvertGUIDtoImmutable $i #Gets immutable ID based on AD 'Ms-Ds-ConsistencyGUID'
        $k = ($f.Mail).trim()
        $l = $f.UserPrincipalName #Azure AD UPN
        $exportResultPath = "C:\ADMT\WGB Exports\PostCutover\TestScript\verificationExport.csv"
        
        
        If($b -eq $Row.'ms-ds-consistencyGUID'){
            $OnPremCheckerMS = $true
                }else{
                    $OnPremCheckerMS = $false
                    }

        If($d -eq $row.UserPrincipalName){
            $OnPremCheckerUPN = $true
            }else{
                $OnPremCheckerUPN = $false
                }

        If($e -eq $row.mail){
            $OnPremCheckerMail = $true
            }else{
                $OnPremCheckerMail = $false
                }

        
        If(($OnPremCheckerMS -eq $true) -and ($OnPremCheckerUPN -eq $true) -and ($OnPremCheckerMail -eq $true)){
            $OnpremChecker = $true
            }else{
                 $OnpremChecker = $false
                 }
                 
        if($g -ne $null){
            $CloudDeletedUser = $true
                }else{
                    $CloudDeletedUser = $false
                    }
        if($j -eq $row.ImmutableIDfromCloud)
            {$CloudImmutableChecker = $true
            }else{
                $CloudImmutableChecker = $false
                }

        if($k -eq $row.mail.trim()){
            $CloudMailChecker = $true
            }else{
                $CloudMailChecker = $false
                    }
        
        if($l -eq $row.UserPrincipalName){
            $CloudUPNCheck = $true
            }else{
                $CloudUPNCheck = $false}
                 
    
        
        
        if(($CloudDeletedUser -eq $false) -and ($CloudImmutableChecker -eq $true) -and ($CloudMailChecker -eq $true) -and ($CloudUPNCheck -eq $true)){
            $Cloud = $true
            }else{
            $Cloud = $false
            }

        
        
           if(($Cloud -eq $true) -and ($OnpremChecker -eq $true)){
                $CloudChecker = $true
                #Write-Output "User $c was migrated succesfully"
                    }else{
                        $CloudChecker = $false
                        Write-Host "user $c was not migrated properly" -ForegroundColor red -BackgroundColor white

             		                       
                      }
                
               $result+= [PSCustomObject]@{ 
                                     CloudUPN = $l
                                     OnPremUPN = $d
                                     OnPremSam = $c
                                     CompleteSuccess = $Cloud
                                     ADCheckCompleteSuccess =  $OnpremChecker
                                     CloudCompleteSuccess =  $CloudChecker   
                                     UPNMatch = $CloudUPNCheck
                                     ImmutableMatch = $CloudImmutableChecker
                                     IsUserDeleted = $CloudDeletedUser
                }
                $result | Export-Csv -Path $exportResultPath -NoTypeInformation 

        }
