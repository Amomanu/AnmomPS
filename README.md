# PowerShell Admin Scripts

PowerShell scripts for Microsoft 365, Azure and Active Directory administration and migrations.

## Featured

| Script | What it does |
|---|---|
| [CopyUsersFromAzuerADtoADVersion2](HybridIdentity/CopyUsersFromAzuerADtoADVersion2.ps1) | Creates on-prem AD accounts for cloud-only users and hard-matches them to Entra ID (ms-DS-ConsistencyGuid / ImmutableId) for Azure AD Connect |
| [EntraIDAppRegistrationCredentialExpiration](EntraID/Applications/EntraIDAppRegistrationCredentialExpiration.ps1) | Azure Automation runbook (Microsoft Graph) that emails app registration secrets and certificates expiring within 30 days |
| [Export-AzADUserMap](EntraID/UsersAndGroups/Export-AzADUserMap.ps1) | Microsoft Graph and Exchange Online export of user data, on-prem sync data, proxy addresses, owned devices and group memberships |
| [PostCopyADMTVerification](ActiveDirectory/ADMT-Migration/PostCopyADMTVerification.ps1) | After an ADMT user copy, finds each user in the target domain through sIDHistory and checks that ms-DS-ConsistencyGuid was kept |
| [Functions](Functions) | Reusable functions for DC builds: registry DWORD set, RAW data-disk setup, NIC DNS check, DCPROMO answer file |

## Folders

| Folder | Covers |
|---|---|
| ActiveDirectory | ADMT migration helpers, bulk AD attribute updates |
| HybridIdentity | Azure AD Connect: sync rules, ms-DS-ConsistencyGuid / ImmutableId matching, synced-user reports, deleted users |
| EntraID | Conditional Access and PIM exports, app registration credential expiry alerts, sign-in and user/group reports |
| Exchange | Distribution lists, role assignment policies |
| Teams | Team owners, private channel inventory |
| SharePoint | Site collection admin on all sites |
| OneDrive | Files On-Demand, Known Folder Move, client reset / tenant switch, permission report |
| Purview-AIP | Removing sensitivity-label encryption from a list of files |
| Migration-TeamsSharePoint | Tenant-to-tenant Teams and OneDrive/SharePoint migrations (ShareGate) |
| Azure | VM Run Command, VM extensions, backup status, Key Vault certificates |
| WindowsEndpoint | Windows Hello for Business, local groups |
| Functions | Reusable functions: registry DWORD set, RAW data-disk setup, NIC DNS check, DCPROMO answer file |


## Usage

Every script has a help header describing what it does, what it needs, what to set before running and any known issues:

```powershell
Get-Help ".\EntraID\Security\ConditionalAccessReport.ps1" -Full
```

- Most scripts are configured by editing the variables at the top (paths, IDs, domains), not through parameters.
- `CopyUsersFromAzuerADtoADVersion2.ps1` is a function library: dot-source it (`. .\script.ps1`) and call the functions shown in its help.
- Each file in `Functions` defines one function: dot-source it, then `Get-Help <FunctionName> -Full`.

## Notes

- Organization names (Contoso, Fabrikam, ...), IDs and credentials are placeholders.
- Several scripts use the legacy AzureAD and MSOnline modules, which Microsoft has retired.
- Some scripts make bulk or destructive changes. Read the header and test in a non-production environment first.
