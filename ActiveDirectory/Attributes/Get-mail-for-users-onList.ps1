<#
.SYNOPSIS
    Exports the mail attribute of the AD users listed in a CSV, skipping users without one.
.DESCRIPTION
    Reads sAMAccountNames from the TargetSam column of $noemailfile and writes SAM and Mail for every
    user whose AD mail attribute is set to $exportcsvpath. The output columns match the input expected
    by WriteEmailfromCsv.ps1.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $noemailfile and $exportcsvpath.
#>


$noemailfile = "C:\Temp\WT-admtfinal.csv"
$exportcsvpath="C:\Temp\mailexport.csv"
$nouser=Import-Csv -Path $noemailfile 
$sams =$nouser.TargetSam

$obj = @()

foreach($row in $sams){

            
            $allAttributes=Get-ADUser -Identity $row -Properties * #|Select-Object mail
            if($allAttributes.mail -ne $null){
            $obj += [PSCustomObject]@{ SAM = $allAttributes.samaccountname
		                               Mail = $allAttributes.mail                       
                                        }
                                        }
            #$allAttributes.mail
            #$allAttributes.UserPrincipalName
            }
$obj|Export-Csv -Path $exportcsvpath -NoTypeInformation

