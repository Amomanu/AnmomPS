<#
.SYNOPSIS
    Converts a text export of users' ms-DS-ConsistencyGuid byte values into the format read by
    Set-MSDSconsistency.ps1.
.DESCRIPTION
    Reads $infile line by line. A line that is not purely numeric is treated as a user identity: a
    "UserStarts" marker and the line itself are written to $outfile (lines containing
    "mS-DS-ConsistencyGuid" are skipped). A numeric line is treated as one byte of the GUID in decimal
    and is written to $outfile in hexadecimal, one byte per line.
.NOTES
    Setup    : set $infile and $outfile. The input must list each user's identity followed by the decimal
               byte values of ms-DS-ConsistencyGuid, one value per line.
    Note     : $outfile is appended to, so delete it before re-running.
#>


function Is-Numeric ($Value)
{
    return $Value -match "^[\d\.]+$"
}

$infile = get-content "C:\Temp\MSDSConsistency.csv"
$outfile = "C:\Temp\MSDS-oneline.csv"
foreach($line in $infile)
    {$val=''
    $numeric=Is-Numeric($line)
     If($numeric -ne "False"){
        if ($line -like "*mS-DS-ConsistencyGuid*"){

        
        }
            else{ 
            "UserStarts"|Out-File $outfile -Append   
            $line|Out-File $outfile -Append}     #Will write name
     }else{
     $val=$val.trim()+[System.Convert]::ToString($line,16)
     
        }
    $val|Out-File $outfile -Append
    Clear-Variable val
    #"UserCompleted"|Out-File $outfile -Append
     }
