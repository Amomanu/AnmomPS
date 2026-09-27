<#
.SYNOPSIS
    Lists the standard (built-in) synchronization rules from an Azure AD (Entra) Connect configuration
    export (work in progress).
.DESCRIPTION
    Reads the exported JSON and, for each entry in onpremisesDirectoryPolicy, collects every rule in
    standardSynchronizationRules with its name, unique identifier, immutable tag, precedence and the
    entry's fullyQualifiedDomainName (connector) into $outputArray. Rules with precedence 101 are
    highlighted on screen.
.NOTES
    Setup    : set the Get-Content path to your export file.
    Output   : results stay in $outputArray (nothing is exported).
    Known issue: the inner loop reads the standard rules of all entries ($customObj) for every entry, so
    with more than one connector the rules are repeated under each connector name.
#>


$json =  Get-Content "C:\Temp\EntraConnect\Staging-DC02-Exported-SynchronizationPolicy.json" -Raw
$converted = ConvertFrom-Json -InputObject $json

$customObj = $converted.onpremisesDirectoryPolicy
$outputArray = [System.Collections.ArrayList]::new()



foreach($object in $customObj){
        $objectName = $object.fullyQualifiedDomainName
        
            foreach($obj in $customObj.standardSynchronizationRules){
                 $customObjN = $null
                 $customObjN = [pscustomobject]@{
                     ConnectorSpace = $objectName
                     Name = $obj.Name
                     UniqueIdentifier = $obj.uniqueIdentifier
                     ImmutableTag = $obj.ImmutableTag
                     Precedence = $obj.Precedence
                     Connector = $object.fullyQualifiedDomainName
                    }
                If($customObjN.Precedence -eq '101'){
                    Write-Host "101!" 
                    Write-Host "Obj. Precedence : $($obj.precedence)"
                    }   
            [void]$outputArray.add($customObjN)
            }
}           
        
       
        

       
        #[void]$outputArray.add($customObjN)
        

        
