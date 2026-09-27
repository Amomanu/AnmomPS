<#
.SYNOPSIS
    Moves the AD users listed in a CSV into one target OU and records the result per user.
.DESCRIPTION
    Reads the CSV in $infile (column SourceName = sAMAccountName, the same file used for ADMT),
    moves each user to the OU set in $OU inside the MoveToOu function and writes one row per user
    (status Success/Failed, samaccountname, OU name) to $outfile.
.NOTES
    Requires : ActiveDirectory module and rights to move the users.
    Setup    : set $OU (inside the MoveToOu function), $infile and $outfile.
    Known issue: the on-screen "Failed for ..." check tests $OBJ instead of $line, so it is not
    reliable - check the status column in the output CSV instead.
#>


function MoveToOu{
 Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         $UserSam 

           )
        $OU="OU=ADMT OU,DC=domain3,DC=subdomain"    #OU to be moved to
        $OUName=(Get-ADObject -Identity $OU).Name
        $cusobj=[PSCustomObject]@{ status = $res.UserPrincipalName|Out-String
		                           samaccountname = $UserSam
		                           OU =  $OUName
                           }
    try{
        Get-ADUser -Identity $UserSam -Properties * | Move-ADObject -TargetPath $OU    
        }catch{
            $cusobj=[PSCustomObject]@{ status = "Failed"
		                               samaccountname = $UserSam
		                               OU =  $OUName
                           }
            return $cusobj
            }
        $cusobj=[PSCustomObject]@{ status = "Success"
		                               samaccountname = $UserSam
		                               OU =  $OUName
                           }
        Return $cusobj    

    }

Clear-Variable obj


$obj = @()
$infile="C:\FabrikamScripts\ADMT test ou move file.csv"    #Path of file with users to be migrated.Same file as for ADMT.
$outfile = "C:\FabrikamScripts\outfile.csv" 

$file=Import-Csv -Path $infile 
foreach($row in $file){

$name=$row.SourceName

$obj += MoveToOu $name 
}

foreach($line in $obj)
    {IF ($OBJ.Status -notlike "*Success*"){
                    Write-Output "Failed for $($obj.samaccountname)"

                    }
                    }
$obj|Export-Csv -Path $outfile -NoTypeInformation
