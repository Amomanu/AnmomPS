<#
.SYNOPSIS
    Picks random Exchange-licensed users and, after a Y/N confirmation for each, adds them to a
    distribution list.
.DESCRIPTION
    Gets all enabled member (non-guest) Azure AD users, keeps those with a successfully provisioned
    service plan whose name contains "EXCHANGE", randomly picks $UserCount of them (25 by default), shows
    each user's name, job title and UPN and asks "Add this user to '<list>'? (Y/N)". Confirmed users are
    added with Add-DistributionGroupMember.
.NOTES
    Requires : AzureAD and ExchangeOnlineManagement modules; connect to both first (the Connect and
               Disconnect lines are commented out).
    Setup    : set $DistributionList and $UserCount.
    Note     : the "Pick 50 random users" comment is outdated - the number comes from $UserCount. The
               "EXCHANGE" match also includes plans such as EXCHANGE_S_FOUNDATION, which can select users
               without a mailbox. License details are read per user, which is slow in large tenants.
#>


# Connect to Exchange Online
#Connect-ExchangeOnline

# Parameters
$DistributionList = "testphishpolicgydistro@contoso.com"
$UserCount = 25

# Step 1: Get all internal users with Exchange Online license
$AllUsers = Get-AzureADUser -All $true | Where-Object {
    $_.UserType -eq "Member" -and $_.AccountEnabled -eq $true
}

# Step 2: Filter users with Exchange Online license
$LicensedUsers = @()
foreach ($user in $AllUsers) {
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId
    foreach ($license in $licenses) {
        if ($license.ServicePlans | Where-Object { $_.ServicePlanName -like "*EXCHANGE*" -and $_.ProvisioningStatus -eq "Success" }) {
            $LicensedUsers += $user
            break
        }
    }
}

# Step 3: Pick 50 random users
$SelectedUsers = $LicensedUsers | Get-Random -Count ([math]::Min($UserCount, $LicensedUsers.Count))

# Step 4: Loop through each user and ask for approval
foreach ($user in $SelectedUsers) {
    $userDetails = Get-AzureADUser -ObjectId $user.ObjectId | Select-Object DisplayName, JobTitle, UserPrincipalName

    Write-Host "`nUser: $($userDetails.DisplayName)"
    Write-Host "Title: $($userDetails.JobTitle)"
    Write-Host "Email: $($userDetails.UserPrincipalName)"
    
    $response = Read-Host "Add this user to '$DistributionList'? (Y/N)"
    
    if ($response -eq "Y") {
        try {
            Add-DistributionGroupMember -Identity $DistributionList -Member $userDetails.UserPrincipalName
            Write-Host "✅ Added $($userDetails.DisplayName)"
        } catch {
            Write-Warning "❌ Failed to add $($userDetails.DisplayName): $_"
        }
    } else {
        Write-Host "⏭️ Skipped $($userDetails.DisplayName)"
    }
}

# Disconnect
#Disconnect-ExchangeOnline -Confirm:$false
