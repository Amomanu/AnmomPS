<#
.SYNOPSIS
    Checks whether the target sAMAccountNames in a migration list already exist in the domain.
.DESCRIPTION
    For each value in the targetsam column of $FileToImportPath, looks up an AD user with that identity
    in the domain the script runs against and writes sam, Conflict (True when a user already exists) and
    Where (that user's distinguished name, or NA) to $filePathtoExport. Useful before an ADMT migration
    to find sAMAccountName conflicts in the target domain.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $FileToImportPath and $filePathtoExport. No -Server is used, so run it against the
               target domain.
#>


$FileToImportPath = "C:\ADMT\NWT Exports\northwindFINAL.csv"
$filePathtoExport = "C:\ADMT\NWT Exports\samsuplicatesreport.csv"
$CSV = Import-Csv -Path $FileToImportPath
$res = @()
foreach($row in $CSV){
    $sam= $row.targetsam
    try{ $us = Get-ADUser -Identity $sam
    $res += [PSCustomObject]@{ 
                                     sam = $sam
                                     Conflict = $true
                                     Where = $us.DistinguishedName
                                    
                }
                }catch{

                $res += [PSCustomObject]@{ 
                                     sam = $sam
                                     Conflict = $false
                                     Where = 'NA'
                                     }

        
    }
}

$res | Export-Csv -Path $filePathtoExport -NoTypeInformation
