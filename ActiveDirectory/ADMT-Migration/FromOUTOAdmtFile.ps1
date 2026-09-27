<#
.SYNOPSIS
    Builds an ADMT include file (SourceName, TargetSam, TargetUPN) from all users in a list of OUs.
.DESCRIPTION
    Reads OU distinguished names from $importFile (column OUDN) and exports the sAMAccountName and
    UserPrincipalName of every user in each OU (including sub-OUs) to $exportFile. It then re-imports
    that list and writes $FINALexport with the columns SourceName and TargetSam (both = sAMAccountName)
    and TargetUPN, in the ADMT include-file format.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $importFile, $exportFile and $FINALexport.
    Note     : $exportFile is appended to, so delete it before re-running. The Sort-Object | Get-Unique
               line only prints to the screen; duplicates are not removed from $FINALexport.
#>


$importFile= "C:\Temp\WGBOUs.csv"
$exportFile= "C:\Temp\WGBmigrationlist.csv"
$FINALexport = "C:\Temp\fINALfORMAT22ND.csv"

$OUs=Import-Csv $importFile

$Obj= @()
foreach($row in $OUs.OUDN){
    
    Get-ADUser -Filter * -SearchBase $row | Select-Object samaccountname,userprincipalname|Export-Csv $exportFile -Append -NoTypeInformation

    

    }

$reimport= Import-Csv -Path $exportFile 

foreach($row in $reimport){
    $row
    $Obj+= [PSCustomObject]@{ SourceName = $row.samaccountname 
                              TargetSam =  $row.samaccountname
                              TargetUPN =  $row.Userprincipalname        		                       
                      }
    Write-Host "wrote to obj"
                      }
   $obj|Sort-Object|Get-Unique 
   $obj|Export-Csv -Path $FINALexport -NoTypeInformation
   #$obj|Export-Csv -Path $exportFile
