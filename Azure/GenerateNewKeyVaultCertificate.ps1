<#
.SYNOPSIS
    Azure Automation runbook that creates a self-signed certificate in Azure Key Vault.
.DESCRIPTION
    Signs in with the Automation account's managed identity (Connect-AzAccount -Identity), selects the
    subscription and creates the certificate "certgen-v0" in the Key Vault "certgen" (resource group
    "CertRot") with a self-signed policy: subject CN=humongousinsurance.com, PKCS#12 format, valid for
    6 months.
.NOTES
    Requires : an Azure Automation account whose managed identity may create certificates in the vault,
               and the Az.Accounts and Az.KeyVault modules.
    Setup    : set the subscription ID, resource group, vault name, certificate name and subject.
    Note     : the certificate name is fixed, so each run adds a new version of the same certificate.
#>


try{
    'Logging in to Azure...'
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Get-azcontext 

set-azcontext -SubscriptionId '22222222-2222-2222-2222-222222222222'   #sandbox subscription
$KeyVault = Get-AzKeyVault -ResourceGroupName 'CertRot' -VaultName 'certgen'
#$KeyVault.VaultName
$Policy = New-AzKeyVaultCertificatePolicy -SecretContentType 'application/x-pkcs12' -SubjectName 'CN=humongousinsurance.com' -IssuerName 'Self' -ValidityInMonths 6
Add-AzKeyVaultCertificate -VaultName $KeyVault.VaultName -Name 'certgen-v0' -CertificatePolicy $Policy
