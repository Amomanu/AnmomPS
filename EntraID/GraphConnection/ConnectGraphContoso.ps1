<#
.SYNOPSIS
    Connects to Microsoft Graph PowerShell as an app registration (client ID + client secret).
.DESCRIPTION
    Installs the MSAL.PS module for all users, gets an app-only access token with Get-MsalToken (client
    credentials from $AppId, $TenantId and $ClientSecret) and connects with Connect-Graph -AccessToken, so
    the Get-Mg* cmdlets you run afterwards use the app's permissions.
.NOTES
    Requires : admin rights (Install-Module -Scope AllUsers), MSAL.PS and Microsoft.Graph.Authentication.
    Setup    : fill in $AppId, $TenantId and $ClientSecret. The app needs Microsoft Graph application
               permissions for whatever you run after connecting.
    Note     : written for Microsoft Graph PowerShell v1; in v2, Connect-MgGraph -AccessToken expects a
               SecureString. Do not store a real client secret in the file.
#>


#Install MSAL.PS module for all users (requires admin rights)
Install-Module MSAL.PS -Scope AllUsers -Force
 
#Generate Access Token to use in the connection string to MSGraph
$AppId = '11111111-1111-1111-1111-111111111111'    #Identity for graph getting users and authentication methods
$TenantId = '00000000-0000-0000-0000-000000000000'
$ClientSecret = '<CLIENT_SECRET>'
 
Import-Module MSAL.PS
$MsalToken = Get-MsalToken -TenantId $TenantId -ClientId $AppId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
 
#Connect to Graph using access token
Connect-Graph -AccessToken $MsalToken.AccessToken

