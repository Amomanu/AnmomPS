
<#
.SYNOPSIS
    Writes ms-DS-ConsistencyGuid values to AD users from the file produced by
    MsDs-consistencyGUIDFIleTransformation.ps1.
.DESCRIPTION
    Reads C:\Temp\MSDS-oneline.csv: each user block starts with a "UserStarts" line, followed by the
    user identity line and the GUID bytes as one- or two-digit hex values. The bytes are joined,
    converted to a GUID and written to the user's ms-DS-ConsistencyGuid with Set-ADUser -Replace. The last
    block is written after the loop.
.NOTES
    Requires : ActiveDirectory module and write access to ms-DS-ConsistencyGuid.
    Setup    : set the Get-Content path.
    WARNING  : when ms-DS-ConsistencyGuid is the Azure AD Connect source anchor, changing it affects how
               the account is matched to its cloud user - test on one user first.
    Note     : the identity line is passed to Set-ADUser -Identity, so it must be a sAMAccountName, DN,
               GUID or SID (a UPN is not accepted). The first "UserStarts" line triggers a Set-ADUser call
               with empty values, so one error at the start is expected.
#>


Clear-Variable upn
Clear-Variable newGuid
Clear-Variable NUME
Clear-Variable guid
Clear-Variable ohh

function get-guid($value){
$hexstring = $value
$guid = [GUID]([byte[]] (-split (($hexstring -replace " ", "") -replace '..', '0x$& ')))
Return $guid
}



$ohh= Get-Content "C:\Temp\MSDS-oneline.csv"
foreach($line in $ohh)
    {
        if($line -eq "UserStarts"){
           $newGUID
           $fin = get-guid ($newGUID)
           Set-ADUser $upn -Replace @{ "ms-Ds-ConsistencyGuid" = $fin}
           #get-guid ($newGUID)
            Clear-Variable newGUID
             }else{$LENGTH=$line.Length
                        if($LENGTH -gt 2){
                                "Upn is $line"
                                $upn=$line.replace(" ","")
                                    }else{
                                        if($LENGTH -eq 1){$line='0'+$line}
                                        $newGUID+=$line
                                    }

                }
            
    }
    $newGUID
    $fin=get-guid ($newGUID)
    Set-ADUser $upn -Replace @{ "ms-Ds-ConsistencyGuid" = $fin}
