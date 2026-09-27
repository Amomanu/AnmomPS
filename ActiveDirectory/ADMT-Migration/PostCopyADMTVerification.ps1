<#
.SYNOPSIS
    After an ADMT user copy, checks that each migrated user exists in the target domain and kept the
    same ms-DS-ConsistencyGuid.
.DESCRIPTION
    For each row in $importfilepath (column SourceName = source sAMAccountName) it reads the user from
    the source DC ($serverSource), finds the target user whose sIDHistory contains the source SID on
    the target DC ($serverDestination) and compares both ms-DS-ConsistencyGuid values (converted to the
    Base64 ImmutableId format). Users that cannot be found are collected in $objectnotfound, users whose
    values differ in $msnotmacthed; matches are printed as "objects match".
.NOTES
    Requires : ActiveDirectory module and read access to both domains.
    Setup    : set $importfilepath, $serverSource and $serverDestination.
    Output   : results stay in the $objectnotfound and $msnotmacthed variables (nothing is exported).
#>


    function ConvertGUIDtoImmutable ($valuetoconvert){
        $guid = [GUID]$valuetoconvert
        $bytearray = $guid.tobytearray() 
        $immutableID = [system.convert]::ToBase64String($bytearray) 
        return $immutableID
    }



$importfilepath = "C:\ADMT\WT Exports\wtadmtfinal.csv"
$Importcsv = Import-Csv -Path $importfilepath
$serverSource = "WTDC01.hq.wingtiptoys.com"
$serverDestination = "fabrikam-dc-01.corp.fabrikam.com"
$objectnotfound = @()
$msnotmacthed = @()
foreach($row in $Importcsv){
    $sa = $row.SourceName
    
    $sourceObject = Get-ADUser -Identity $sa -Server $serverSource -Properties *
    $SourceSID= $sourceObject.sid
    $SourceSidValue = $SourceSID.Value
    
    $destinationObject = Get-ADUser -Filter "sidhistory -like '$($sourceObject.sid)'" -Server $serverDestination -Properties *
    $destinationObject.SidHistory

    if($destinationObject -eq $null){
        Write-Host "Object could not be find based on SID"
        $objectnotfound+= $row
    }else{
            if((ConvertGUIDtoImmutable $sourceObject.'mS-DS-ConsistencyGuid') -eq (ConvertGUIDtoImmutable $destinationObject.'mS-DS-ConsistencyGuid')){

            Write-Host "objects match"
            }else{
                $msnotmacthed += $row

                }
        

        }
                
    

   
    
    }
    




    #$sourceUser = Get-ADUser -filter "userprincipalname -eq '$sourceUPN'" -server server.domain -Credential $Admin -Properties * -ErrorAction SilentlyContinue
