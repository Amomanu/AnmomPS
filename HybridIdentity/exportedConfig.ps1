<#
.SYNOPSIS
    Lists the custom synchronization rules from an Azure AD (Entra) Connect configuration export.
.DESCRIPTION
    Reads the exported JSON (*-Exported-SynchronizationPolicy-*.json) and, for each rule in
    onpremisesDirectoryPolicy.customSynchronizationRules, collects name, description, source and target
    object type, link type, scoping filter (attribute, condition, value), precedence, direction and
    attribute mappings (destination and source) into $outputArray.
.NOTES
    Setup    : set the Get-Content path to your export file.
    Output   : results stay in $outputArray (nothing is exported), for example:
               $outputArray | Export-Csv .\CustomRules.csv -NoTypeInformation
#>


$json =  Get-Content "C:\Temp\EntraConnect\Staging-DC01-Exported-SynchronizationPolicy.json" -Raw
$converted = ConvertFrom-Json -InputObject $json

$customObj = $converted.onpremisesDirectoryPolicy.customSynchronizationRules

$outputArray = [System.Collections.ArrayList]::new()



foreach($object in $customObj){
        #$object
        
        

        $customObj1 = [pscustomobject]@{
            Name = $object.Name
            Description = $object.description
            SourceObject = $object.source
            TargetObject = $object.target
            LinkType = $object.linkType
            ScopeFiltersAttribute = $object.scopeFilters.attribute|Out-String
            ScopeFiltersCondition = $object.scopeFilters.Condition|Out-String
            ScopeFiltersValue = $object.scopeFilters.Value|Out-String
            Precedence = $object.precedence
            Direction = $object.direction
            AttributeMappingsDestination = $object.attributeMappings.destination|Out-String
            AttributeMappingsSource = $object.attributeMappings.Source|Out-String


            }
        [void]$outputArray.add($customObj1)
        }

        
        # $object holds connectorName
            #$converted.onpremisesDirectoryPolicy.customSyncronizationRules
        

<#$customObj1 = [pscustomobject]@{
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

        #>