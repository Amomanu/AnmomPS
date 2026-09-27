<#
.SYNOPSIS
    Exports all Conditional Access policies to a CSV, one row per policy.
.DESCRIPTION
    Signs in interactively (a browser window opens; authorization-code flow with admin consent) using an
    Azure AD app registration ($ClientID / $ClientSecret), reads all policies from
    https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies (following paging, waiting 45
    seconds when throttled) and flattens each policy into one row: ID, name, state, last modified,
    conditions (users, groups, roles, guests/external users, applications, user actions, authentication
    context, locations, platforms, client app types, user/sign-in/service principal risk, devices,
    client applications), grant controls and session controls.
.NOTES
    Requires : Windows (the sign-in window is a Windows Forms browser control) and an app registration
               with the redirect URI https://login.microsoftonline.com/common/oauth2/nativeclient and the
               delegated Microsoft Graph permission Policy.Read.All.
    Setup    : fill in $ClientID and $ClientSecret and set the Export-Csv path.
    Note     : values are exported as raw IDs; users, groups, roles and apps are not resolved to names.
    Known issues: the output path is hard-coded as ".csv" (a file with no name in the current folder)
    and $Outpath is not used. The PolicyConditionsUsersIncludeGroups column is always empty because of a
    variable-name typo ($policy_Conditions_Users_IncludeGroup).
#>


# Client ID for the Azure AD application with Microsoft Graph permissions.
$ClientID = ''

# Client secret for the Azure AD application with Microsoft Graph permissions.
$ClientSecret = ''



function Connect-MsGraphAsDelegated {
    param (
        [string]$ClientID,
        [string]$ClientSecret
    )


    # Declarations.
    $Resource = "https://graph.microsoft.com"
    $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"


    # Force TLS 1.2.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


    # UrlEncode the ClientID and ClientSecret and URL's for special characters.
    Add-Type -AssemblyName System.Web
    $ClientIDEncoded = [System.Web.HttpUtility]::UrlEncode($ClientID)
    $ClientSecretEncoded = [System.Web.HttpUtility]::UrlEncode($ClientSecret)
    $ResourceEncoded = [System.Web.HttpUtility]::UrlEncode($Resource)
    $RedirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($RedirectUri)


    # Function to popup Auth Dialog Windows Form.
    function Get-AuthCode {
        Add-Type -AssemblyName System.Windows.Forms
        $Form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640 }
        $Web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = ($Url -f ($Scope -join "%20")) }
        $DocComp = {
            $Global:uri = $Web.Url.AbsoluteUri        
            if ($Global:uri -match "error=[^&]*|code=[^&]*") { $Form.Close() }
        }

        $Web.ScriptErrorsSuppressed = $true
        $Web.Add_DocumentCompleted($DocComp)
        $Form.Controls.Add($Web)
        $Form.Add_Shown( { $Form.Activate() })
        $Form.ShowDialog() | Out-Null
        $QueryOutput = [System.Web.HttpUtility]::ParseQueryString($Web.Url.Query)
        $Output = @{ }

        foreach ($Key in $QueryOutput.Keys) {
            $Output["$Key"] = $QueryOutput[$Key]
        }

        #$Output
    }


    # Get AuthCode.
    $Url = "https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&redirect_uri=$RedirectUriEncoded&client_id=$ClientID&resource=$ResourceEncoded&prompt=admin_consent&scope=$ScopeEncoded"
    Get-AuthCode


    # Extract Access token from the returned URI.
    $Regex = '(?<=code=)(.*)(?=&)'
    $AuthCode = ($Uri | Select-string -pattern $Regex).Matches[0].Value


    # Get Access Token.
    $Body = "grant_type=authorization_code&redirect_uri=$RedirectUri&client_id=$ClientId&client_secret=$ClientSecretEncoded&code=$AuthCode&resource=$Resource"
    $TokenResponse = Invoke-RestMethod https://login.microsoftonline.com/common/oauth2/token -Method Post -ContentType "application/x-www-form-urlencoded" -Body $Body -ErrorAction "Stop"


    $TokenResponse.access_token
}


function Get-MsGraph {

    param (
        [parameter(Mandatory = $true)]
        $AccessToken,

        [parameter(Mandatory = $true)]
        $Uri
    )

    # Check if authentication was successfull.
    if ($AccessToken) {
        # Format headers.
        $HeaderParams = @{
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $AccessToken"
        }


        # Create an empty array to store the result.
        $QueryResults = @()


        # Invoke REST method and fetch data until there are no pages left.
        $Results = ""
        $StatusCode = ""

        # Invoke REST method and fetch data until there are no pages left.
        do {
            $Results = ""
            $StatusCode = ""

            do {
                try {
                    $Results = Invoke-RestMethod -Headers $HeaderParams -Uri $Uri -UseBasicParsing -Method "GET" -ContentType "application/json"

                    $StatusCode = $Results.StatusCode
                } catch {
                    $StatusCode = $_.Exception.Response.StatusCode.value__

                    if ($StatusCode -eq 429) {
                        Write-Warning "Got throttled by Microsoft. Sleeping for 45 seconds..."
                        Start-Sleep -Seconds 45
                    }
                    else {
                        Write-Error $_.Exception
                    }
                }
            } while ($StatusCode -eq 429)

            if ($Results.value) {
                $QueryResults += $Results.value
            }
            else {
                $QueryResults += $Results
            }

            $uri = $Results.'@odata.nextlink'
        } until (!($uri))


        # Return the result.
        $QueryResults
    }
    else {
        Write-Error "No Access Token"
    }
}




#Getting AccessToken

$AccessToken = Connect-MsGraphAsDelegated -ClientID $ClientID -ClientSecret $ClientSecret

# Get all Conditional Access policies.
Write-Verbose -Verbose -Message "Getting all Conditional Access policies..."
$Uri = 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'


$CAPolicies = @(Get-MsGraph -AccessToken $AccessToken -Uri $Uri)
Write-Verbose -Verbose -Message "Found $(($CAPolicies).Count) policies..."
$Rslt = @()

foreach($pol in $CAPolicies){

    $PolicyID = $pol.id
    $PolicyDisplayName = $pol.displayName
    $LastModified = $pol.modifiedDateTime
    $PolicyState = $pol.state
    $Policy_Conditions_UserRiskLevel = $pol.conditions.userRiskLevels
    $policy_Conditions_SignInRiskLevels = $pol.conditions.signInRiskLevels
    $policy_Conditions_ClientAppTypes = $pol.conditions.clientAppTypes
    $policy_Conditions_servicePrincipalRiskLevels = $pol.conditions.servicePrincipalRiskLevels
    $policy_Conditions_Locations_includeLocations = $pol.conditions.locations.includeLocations
    $policy_Conditions_Locations_excludeLocations = $pol.conditions.locations.excludeLocations
    $policy_Conditions_Devices = $pol.conditions.devices
    $policy_Conditions_ClientApplications = $pol.conditions.clientApplications
    $policy_Conditions_Applications_IncludeApplications = $pol.conditions.applications.includeApplications
    $policy_Conditions_Applications_ExcludeApplications = $pol.conditions.applications.excludeApplications
    $policy_Conditions_Applications_IncludeUserActions = $pol.conditions.applications.includeUserActions
    $policy_Conditions_Applications_includeAuthenticationContext = $pol.conditions.applications.includeAuthenticationContextClassReferences
    $policy_Conditions_Users_includeUsers = $pol.conditions.users.includeUsers
    $policy_Conditions_Users_excludeUsers= $pol.conditions.users.excludeUsers
    $policy_Conditions_Users_IncludeGroups= $pol.conditions.users.includeGroups
    $policy_Conditions_Users_excludeGroups= $pol.conditions.users.excludeGroups
    $policy_Conditions_Users_includeRoles= $pol.conditions.users.includeRoles
    $policy_Conditions_Users_excludeRoles = $pol.conditions.users.excludeRoles
    $policy_Conditions_Users_includeExternalorGuests= $pol.conditions.users.includeGuestsOrExternalUsers
    $policy_Conditions_Users_excludeExternalorGuests= $pol.conditions.users.excludeGuestsOrExternalUsers
    $policy_Conditions_Platforms_includePlatforms = $pol.conditions.platforms.includePlatforms
    $policy_Conditions_Platforms_excludePlatforms = $pol.conditions.platforms.excludePlatforms
    $policy_GrantControls_Operator = $pol.grantControls.operator
    $policy_GrantControls_builtInControls = $pol.grantControls.builtInControls
    $policy_GrantControls_customAuthenticationFactors = $pol.grantControls.customAuthenticationFactors
    $policy_GrantControls_authenticationStrength = $pol.grantControls.authenticationStrength
    $policy_SessionControl_disableResilienceDefaults = $pol.sessionControls.disableResilienceDefaults
    $policy_SessionControl_applicationEnforcedRestrictions = $pol.sessionControls.applicationEnforcedRestrictions
    $policy_SessionControl_CloudAppSecurity_CloudAppSecurityType = $pol.sessionControls.cloudAppSecurity.cloudAppSecurityType
    $policy_SessionControl_CloudAppSecurity_isEnabled = $pol.sessionControls.cloudAppSecurity.isEnabled
    $policy_SessionControl_SignInFrequency_Value = $pol.sessionControls.signInFrequency.value
    $policy_SessionControl_SignInFrequency_type = $pol.sessionControls.signInFrequency.type
    $policy_SessionControl_SignInFrequency_AuthenticationType = $pol.sessionControls.signInFrequency.authenticationType
    $policy_SessionControl_SignInFrequency_FrequencyInterval = $pol.sessionControls.signInFrequency.frequencyInterval
    $policy_SessionControl_SignInFrequency_isEnabled = $pol.sessionControls.signInFrequency.isEnabled
    $policy_SessionControl_persistentBrowser_Mode = $pol.sessionControls.persistentBrowser.mode
    $policy_SessionControl_persistentBrowser_isEnabled = $pol.sessionControls.persistentBrowser.isEnabled

    


    
    $Rslt += [pscustomobject]@{
            PolicyID = $PolicyID
            PolicyState = $PolicyState
            PolicyName = $PolicyDisplayName
            PolicyLastModified = $LastModified
            PolicyConditionsUserRisk = $Policy_Conditions_UserRiskLevel |Out-String
            PolicyConditionsSignInRiskLevels = $policy_Conditions_SignInRiskLevels |Out-String
            PolicyConditionsClientAppTypes = $policy_Conditions_ClientAppTypes |Out-String 
            PolicyConditionsservicePrincipalRiskLevels = $policy_Conditions_servicePrincipalRiskLevels |Out-String
            PolicyConditionsLocationsInclude = $policy_Conditions_Locations_includeLocations |Out-String
            PolicyConditionsLocationsExclude = $policy_Conditions_Locations_excludeLocations |Out-String
            PolicyConditionsDevices = $policy_Conditions_Devices |Out-String
            PolicyConditionsClientApplications = $policy_Conditions_ClientApplications|Out-String
            PolicyConditionsApplicationsIncludeApplication = $policy_Conditions_Applications_IncludeApplications|Out-String
            PolicyConditionsApplicationsExcludeApplications = $policy_Conditions_Applications_ExcludeApplications |Out-String
            PolicyConditionsApplicationsIncludeUserActions = $policy_Conditions_Applications_IncludeUserActions|Out-String
            PolicyConditionsApplicationsincludeAuthenticationContext = $policy_Conditions_Applications_includeAuthenticationContext|Out-String
            PolicyConditionsUsersincludeUsers = $policy_Conditions_Users_includeUsers|Out-String
            PolicyConditionsUsersexcludeUsers= $policy_Conditions_Users_excludeUsers|Out-String
            PolicyConditionsUsersIncludeGroups= $policy_Conditions_Users_IncludeGroup|Out-String
            PolicyConditionsUsersexcludeGroups= $policy_Conditions_Users_excludeGroups|Out-String
            PolicyConditionsUsersincludeRoles= $policy_Conditions_Users_includeRoles|Out-String
            PolicyConditionsUsersexcludeRoles = $policy_Conditions_Users_excludeRoles|Out-String
            PolicyConditionsUsersincludeExternalorGuests = $policy_Conditions_Users_includeExternalorGuests|Out-String
            PolicyConditionsUsersexcludeExternalorGuests= $policy_Conditions_Users_excludeExternalorGuests|Out-String
            PolicyConditionsPlatformsincludePlatforms = $policy_Conditions_Platforms_includePlatforms|Out-String
            PolicyConditionsPlatformsexcludePlatforms =$policy_Conditions_Platforms_excludePlatforms|Out-String
            PolicyGrantControlsOperator =$policy_GrantControls_Operator|Out-String
            PolicyGrantControlsbuiltInControls = $policy_GrantControls_builtInControls|Out-String
            PolicyGrantControlscustomAuthenticationFactors = $policy_GrantControls_customAuthenticationFactors|Out-String
            PolicyGrantControlsauthenticationStrength = $policy_GrantControls_authenticationStrength|Out-String
            PolicySessionControldisableResilienceDefaults = $policy_SessionControl_disableResilienceDefaults|Out-String
            PolicySessionControlapplicationEnforcedRestrictions = $policy_SessionControl_applicationEnforcedRestrictions|Out-String
            PolicySessionControlCloudAppSecurityCloudAppSecurityType = $policy_SessionControl_CloudAppSecurity_CloudAppSecurityType|Out-String
            PolicySessionControlCloudAppSecurityisEnabled = $policy_SessionControl_CloudAppSecurity_isEnabled|Out-String
            PolicySessionControlSignInFrequencyValue = $policy_SessionControl_SignInFrequency_Value|Out-String
            PolicySessionControlSignInFrequencytype = $policy_SessionControl_SignInFrequency_type|Out-String
            PolicySessionControlSignInFrequencyAuthenticationType = $policy_SessionControl_SignInFrequency_AuthenticationType|Out-String
            PolicySessionControlSignInFrequencyFrequencyInterval = $policy_SessionControl_SignInFrequency_FrequencyInterval|Out-String
            PolicySessionControlSignInFrequencyisEnabled = $policy_SessionControl_SignInFrequency_isEnabled|Out-String
            PolicySessionControlpersistentBrowserMode = $policy_SessionControl_persistentBrowser_Mode|Out-String
            PolicySessionControlpersistentBrowserisEnabled = $policy_SessionControl_persistentBrowser_isEnabled|Out-String
        }
    }
$Outpath = ""
    $Rslt | Export-Csv -Path ".csv" -NoTypeInformation -Encoding UTF8
