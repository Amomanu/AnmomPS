<#
.SYNOPSIS
    Azure Automation runbook that emails a list of app registration secrets and certificates expiring
    within the next 30 days.
.DESCRIPTION
    Connects to Microsoft Graph as an app registration (tenant ID, client ID and client secret come from
    the Automation variables TENANT_ID, CLIENT_ID and CLIENT_SECRET), reads all app registrations
    (Get-MgApplication -All) and lists every client secret and certificate with app name, app ID,
    credential ID and expiry date. Credentials that expire within the next 30 days (and have not expired
    yet) are sent as a plain-text email with the subject "TokenExpiration" from the SENDER mailbox to
    DESTINATION, with CC, through Send-MgUserMail.
.NOTES
    Requires : an Azure Automation account with the Microsoft.Graph.Authentication,
               Microsoft.Graph.Applications and Microsoft.Graph.Users.Actions (Send-MgUserMail) modules,
               and the Automation variables TENANT_ID, CLIENT_ID, CLIENT_SECRET, DESTINATION, SENDER and
               CC. The app registration needs the Microsoft Graph application permissions
               Application.Read.All and Mail.Send.
    Note     : credentials that have already expired are not reported. An email is sent on every run,
               also when nothing is about to expire (the body is then empty).
#>


Import-Module Microsoft.Graph.Authentication -verbose
Import-Module Microsoft.Graph.Applications -verbose

$tenantId = Get-AutomationVariable -Name TENANT_ID
$clientId = Get-AutomationVariable -Name CLIENT_ID
$clientSecret = Get-AutomationVariable -Name CLIENT_SECRET
$destinationEmail = Get-AutomationVariable -Name DESTINATION
$senderEmail = Get-AutomationVariable -Name SENDER
$cc = Get-AutomationVariable -Name CC

$securePassword = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securePassword
Connect-MgGraph -TenantId $tenantId -Credential $cred -NoWelcome
Get-MgContext 


$applications = Get-MgApplication -All
#$applications
$logData = @()
foreach ($app in $applications) {
    foreach ($secret in $app.PasswordCredentials) {
        $logData += [PSCustomObject]@{
            AppName = $app.DisplayName
            AppId = $app.AppId
            CredentialType = "Secret"
            CredentialId = $secret.KeyId
            ExpirationDate = $secret.EndDateTime
        }
    }

    foreach ($certificate in $app.KeyCredentials) {
        $logData += [PSCustomObject]@{
            AppName = $app.DisplayName
            AppId = $app.AppId
            CredentialType = "Certificate"
            CredentialId = $certificate.KeyId
            ExpirationDate = $certificate.EndDateTime
        }
    }
}


$now = Get-Date
$threshold = $now.AddDays(30)
$output = $logData | Where-Object{$_.ExpirationDate -ne $null -and $_.ExpirationDate -le $threshold -and $_.ExpirationDate -gt $now}
$output = $output| Out-string


$params = @{
    Message = @{
        Subject = "TokenExpiration"
        Body = @{
            ContentType = "Text"
            Content = "$output"
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = "$destinationEmail"
                }
            }
        )
        CcRecipients = @(
            @{
                EmailAddress = @{
                    Address = "$cc"
                }
            }
        )
        <#Attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                name = $filenamewithdate
                contentType = "text/csv"
                contentBytes = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logfile))
            }
        )#>
    }
    SaveToSentItems = $true
}

# Send the email using the Send-MgUserMail cmdlet
Send-MgUserMail -UserId "$senderEmail" -BodyParameter $params
