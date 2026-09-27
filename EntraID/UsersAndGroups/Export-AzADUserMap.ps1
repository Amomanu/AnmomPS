<#
.SYNOPSIS
    Exports four Entra ID reports: user data, proxy addresses, owned devices and group memberships.
.DESCRIPTION
    Connects to Microsoft Graph and Exchange Online when not already connected, then processes either
    the users listed in $InputFilePath (identifier column $IDHeader) or, when $InputFilePath is empty,
    all users. For each user it collects profile fields, manager, licenses (SKU part numbers), mailbox
    forwarding addresses, on-premises sync data (ImmutableId converted to the on-prem GUID, SID, DN,
    extension attributes 1-15), proxy addresses, owned devices and group memberships (typed as dynamic
    group, the Exchange recipient type for distribution/mail-enabled security groups, 365Group or
    SecurityGroup). It writes four CSVs to $OutputFolderPath:
    <TenantName>-EntraIDUserData_, -EntraIDUserProxies_, -EntraIDUserDevices_ and
    -EntraIDUserMembership_<date>.csv.
.NOTES
    Requires : Microsoft Graph PowerShell v2 (Microsoft.Graph.Users; Connect-MgGraph -NoWelcome) and
               ExchangeOnlineManagement.
    Setup    : set $TenantName (only used in the file names), $InputFilePath (empty = all users),
               $IDHeader and $OutputFolderPath.
    Note     : the comment in the script says guests are excluded, but no filter is applied - all
               users are processed. The connection requests write scopes (User.ReadWrite.All,
               Directory.ReadWrite.All) although the script only reads. Export-Csv uses -NoClobber, so a
               second run on the same day fails unless the old files are moved.
#>


#This script will export 4 reports:
#  - Azure AD user data report
#  - Azure AD user proxy addresses report
#  - Azure AD user owned devices report
#  - Azure AD user group membership report

#___________________________[PARAMETERS]___________________________

#Enter the tenant name
$TenantName = "Test"

#[OPTIONAL] Enter the file path for an input CSV file
$InputFilePath = "C:\Temp\test.csv"

#[OPTIONAL] If using an input file, enter the column name with the object's identifier.
#Example: UserPrincipalName, ExternalDirectoryObjectID, SID...
$IDHeader = "UPN"

#Enter the output folder path. Do not include the last "\"
$OutputFolderPath = "C:\Temp"

#__________________________________________________________________

#Validate connection to MgGraph
Try{
    Write-Host "Validating connection to Microsoft Graph.." -ForegroundColor Cyan
    Get-MgUser -Top 1 -ErrorAction Stop | Out-Null
    Write-Host "  Connected to Microsoft Graph" -ForegroundColor Green
}
Catch{
    Write-Host "  Not connected to Microsoft Graph" -ForegroundColor Yellow
    Write-Host "  Establishing connection..."

    Connect-MgGraph -Scopes User.ReadWrite.All, Directory.ReadWrite.All -NoWelcome

    Write-Host "  Connected to Microsoft Graph" -ForegroundColor Green
}

#Validate connection to EXO
Try{
    Write-Host "Validating connection to Exchange Online..." -ForegroundColor Cyan
    Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
    Write-Host "  Connected to Exchange Online" -ForegroundColor Green
}
Catch{
    Write-Host "  Not connected to Exchange Online" -ForegroundColor Yellow
    Write-Host "  Establishing connection..."

    Connect-ExchangeOnline | Out-Null

    Write-Host "Connected to Exchange Online" -ForegroundColor Green
}

$UserDataOutputLog = [System.Collections.ArrayList]::new()
$ProxyAddressOutputLog = [System.Collections.ArrayList]::new()
$OwnedDevicesOutputLog = [System.Collections.ArrayList]::new()
$GroupMembershipsOutputLog = [System.Collections.ArrayList]::new()
$i = 1

If($InputFilePath){
    $CSV = Import-Csv -Path $InputFilePath
    $mgUsers = @()

    Foreach($row in $CSV){
        $mgUser = $null
        $mgUser = Get-MgUser -UserId "$($row.$IDHeader)" -ExpandProperty Manager -Property `
            DisplayName,`
            GivenName,`
            SurName,`
            UserPrincipalName,`
            Mail,`
            MailNickName,`
            Manager,`
            ProxyAddresses,`
            UserType,`
            AccountEnabled,`
            OnPremisesSyncEnabled,`
            CompanyName,`
            JobTitle,`
            EmployeeId,`
            EmployeeHireDate,`
            EmployeeType,`
            Country,`
            State,`
            City,`
            StreetAddress,`
            PostalCode,`
            MobilePhone,`
            OnPremisesExtensionAttributes,`
            CreatedDateTime,`
            Id,`
            OnPremisesImmutableId,`
            OnPremisesSecurityIdentifier,`
            OnPremisesDistinguishedName

        $mgUsers += $mgUser
    }   
}
Else{
    #Get all Azure AD users that are not guests
    $mgUsers = $null
    $mgUsers = Get-MgUser -All -ExpandProperty Manager -Property `
        DisplayName,`
        GivenName,`
        SurName,`
        UserPrincipalName,`
        Mail,`
        MailNickName,`
        Manager,`
        ProxyAddresses,`
        UserType,`
        AccountEnabled,`
        OnPremisesSyncEnabled,`
        CompanyName,`
        JobTitle,`
        EmployeeId,`
        EmployeeHireDate,`
        EmployeeType,`
        Country,`
        State,`
        City,`
        StreetAddress,`
        PostalCode,`
        MobilePhone,`
        OnPremisesExtensionAttributes,`
        CreatedDateTime,`
        Id,`
        OnPremisesImmutableId,`
        OnPremisesSecurityIdentifier,`
        OnPremisesDistinguishedName
}

$distroGroups = $null
$unifiedGroups = $null

$distroGroups = Get-DistributionGroup -ResultSize Unlimited
$unifiedGroups = Get-UnifiedGroup -ResultSize Unlimited

Foreach($user in $mgUsers){

    Write-Host "($i/$($mgUsers.Count)) Retrieving data for '$($user.UserPrincipalName)'..." -ForegroundColor Cyan
    $EXOMailbox = $null
    $EXOMailbox = Get-EXOMailbox -Identity $user.id -Properties ForwardingAddress, ForwardingSMTPAddress

    #Get user's licenses
    $Licenses = $null
    $Licenses = Get-MgUserLicenseDetail -UserId $user.Id

    #Check for forwarding address
    $InternalForwardingAddress = $null

    If($EXOMailbox.ForwardingAddress){
        $InternalForwardingAddress = (Get-EXORecipient -Identity $EXOMailbox.ForwardingAddress).PrimarySMTPAddress
    }

    #Build user data output table row
    $OutputLogRow = $null
    $OutputLogRow = $user | Select `
        DisplayName,`
        GivenName,`
        SurName,`
        UserPrincipalName,`
        Mail,`
        MailNickName,`
        @{Name="ProxyAddresses";Expression={$_.proxyaddresses -join ";"}},`
        @{Name="InternalForwardingAddress";Expression={$InternalForwardingAddress}},`
        @{Name="ExternalForwardingAddress";Expression={($EXOMailbox.forwardingSMTPAddress -split ":")[1]}},`
        UserType,`
        @{Name="Manager";Expression={$_.Manager.AdditionalProperties.userPrincipalName}},`
        AccountEnabled,`
        OnPremisesSyncEnabled,`
        @{Name="AssignedLicenses";Expression={$Licenses.SkuPartNumber -join ";"}},`
        CompanyName,`
        JobTitle,`
        EmployeeId,`
        EmployeeHireDate,`
        EmployeeType,`
        Country,`
        State,`
        City,`
        StreetAddress,`
        PostalCode,`
        MobilePhone,`
        CreatedDateTime,`
        Id,`
        OnPremisesImmutableId,`
        @{Name="OnPremisesGUID";Expression={[Guid]([Convert]::FromBase64String($_.OnPremisesImmutableId))}},`
        OnPremisesSecurityIdentifier,`
        OnPremisesDistinguishedName,`
        @{Name="OnPremisesExtensionAttributes1";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute1}},`
        @{Name="OnPremisesExtensionAttributes2";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute2}},`
        @{Name="OnPremisesExtensionAttributes3";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute3}},`
        @{Name="OnPremisesExtensionAttributes4";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute4}},`
        @{Name="OnPremisesExtensionAttributes5";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute5}},`
        @{Name="OnPremisesExtensionAttributes6";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute6}},`
        @{Name="OnPremisesExtensionAttributes7";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute7}},`
        @{Name="OnPremisesExtensionAttributes8";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute8}},`
        @{Name="OnPremisesExtensionAttributes9";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute9}},`
        @{Name="OnPremisesExtensionAttributes10";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute10}},`
        @{Name="OnPremisesExtensionAttributes11";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute11}},`
        @{Name="OnPremisesExtensionAttributes12";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute12}},`
        @{Name="OnPremisesExtensionAttributes13";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute13}},`
        @{Name="OnPremisesExtensionAttributes14";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute14}},`
        @{Name="OnPremisesExtensionAttributes15";Expression={$_.OnPremisesExtensionAttributes.OnPremisesExtensionAttribute15}}

    [void]$UserDataOutputLog.Add($OutputLogRow)
    
    #Build proxy addresses table row
    Foreach($ProxyAddress in $user.ProxyAddresses){
        $ProxyAddressOutputLogRow = [pscustomobject]@{
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            ProxyAddress = ($ProxyAddress -split ":")[1]
            ProxyType = ($ProxyAddress -split ":")[0]
            ProxyDomain = ($ProxyAddress -split "@")[1]
            UserObjectId = $user.Id
        }

        [void]$ProxyAddressOutputLog.Add($ProxyAddressOutputLogRow)
    }

    #Get user's owned devices
    $OwnedDevices = $null
    $OwnedDevices = Get-MgUserOwnedDevice -UserId $user.Id

    #Build owned devices table row
    Foreach($OwnedDevice in $OwnedDevices){
        $OwnedDevicesOutputLogRow = $null
        $OwnedDevicesOutputLogRow = [pscustomobject]@{
            Owner = $user.UserPrincipalName
            OwnerObjectId = $user.Id
            DisplayName = $OwnedDevice.AdditionalProperties.displayName
            AccountEnabled = $OwnedDevice.AdditionalProperties.accountEnabled
            deviceOwnership = $OwnedDevice.AdditionalProperties.deviceOwnership
            EnrollmentType = $OwnedDevice.AdditionalProperties.enrollmentType
            IsManaged = $OwnedDevice.AdditionalProperties.isManaged
            OperatingSystem = $OwnedDevice.AdditionalProperties.operatingSystem
            Manufacturer = $OwnedDevice.AdditionalProperties.manufacturer
            Model = $OwnedDevice.AdditionalProperties.model
            ApproximateLastSignInDateTime = $OwnedDevice.AdditionalProperties.approximateLastSignInDateTime
            CreatedDateTime = $OwnedDevice.AdditionalProperties.createdDateTime
            DeviceId = $OwnedDevice.AdditionalProperties.deviceId
        }

        [void]$OwnedDevicesOutputLog.Add($OwnedDevicesOutputLogRow)

    }

    #Get user's group membership
    $GroupMemberships = $null
    $GroupMemberships = Get-MgUserMemberOf -UserId $user.id 
    
    #Build group membership table row
    Foreach($GroupMembership in $GroupMemberships){
        $Group = $null
        $Group = $GroupMembership.AdditionalProperties
        
        $GroupType = $null 
        If($Group.groupTypes -like "*Dynamic*"){
            $GroupType = "DynamicGroup"
        }
        Else{
            If($distroGroups | Where-Object {$_.ExternalDirectoryObjectID -eq $GroupMembership.Id}){
                $GroupType = ($distroGroups | Where-Object {$_.ExternalDirectoryObjectID -eq $GroupMembership.Id}).RecipientTypeDetails
            }
            ElseIf($unifiedGroups | Where-Object {$_.ExternalDirectoryObjectID -eq $GroupMembership.Id}){
                $GroupType = "365Group"
            }
            Else{
                $GroupType = "SecurityGroup"
            }
        }

        $GroupMembershipsOutputLogRow = $null
        $GroupMembershipsOutputLogRow = [pscustomobject]@{
            MemberUPN = $user.UserPrincipalName
            MemberObjectId = $user.Id
            GroupDisplayName = $Group.displayName
            GroupMailNickName = $Group.mailNickname
            GroupType = $GroupType
            GroupMailEnabled = $Group.mailEnabled
            GroupSecurityEnabled = $Group.securityEnabled
            GroupObjectID = $GroupMembership.Id

        }

        [void]$GroupMembershipsOutputLog.Add($GroupMembershipsOutputLogRow)
    }

    $i++

    }

#Export logs
$Date = $null
$Date = Get-Date -Format MM.dd.yy

Write-Host "Exporting user data report to '$OutputFolderPath\$TenantName-EntraIDUserData_$Date.csv...'" -ForegroundColor Green
$UserDataOutputLog | Export-Csv "$OutputFolderPath\$TenantName-EntraIDUserData_$Date.csv" -NoTypeInformation -NoClobber

Write-Host "Exporting proxy address report to '$OutputFolderPath\$TenantName-EntraIDUserProxies_$Date.csv...'" -ForegroundColor Green
$ProxyAddressOutputLog | Export-Csv "$OutputFolderPath\$TenantName-EntraIDUserProxies_$Date.csv" -NoTypeInformation -NoClobber

Write-Host "Exporting owned devices report to '$OutputFolderPath\$TenantName-EntraIDUserDevices_$Date.csv'" -ForegroundColor Green
$OwnedDevicesOutputLog | Export-Csv "$OutputFolderPath\$TenantName-EntraIDUserDevices_$Date.csv" -NoTypeInformation -NoClobber

Write-Host "Exporting group membership report to '$OutputFolderPath\$TenantName-EntraIDUserMembership_$Date.csv'" -ForegroundColor Green
$GroupMembershipsOutputLog | Export-Csv "$OutputFolderPath\$TenantName-EntraIDUserMembership_$Date.csv" -NoTypeInformation -NoClobber

Write-Host "Done!" -ForegroundColor Green