<#
.SYNOPSIS
    Exports Azure AD role assignments from Privileged Identity Management (PIM), one CSV per role.
.DESCRIPTION
    Reads all Azure AD roles known to PIM (Get-AzureADMSPrivilegedRoleDefinition, provider aadRoles) and,
    for each role, its assignments (Get-AzureADMSPrivilegedRoleAssignment). Each assignment's user is
    resolved and RoleName, UserPrincipalName and AssignmentType (e.g. Eligible or Active) are written to
    "<$savePath>\<role name>.csv".
.NOTES
    Requires : the legacy AzureADPreview module and Connect-AzureAD.
    Setup    : set $savePath, put your tenant ID in the Get-AzureADMSPrivilegedRoleDefinition line and
               replace the "tenantID" placeholder in the Get-AzureADMSPrivilegedRoleAssignment line with
               the same tenant ID.
    Note     : only user assignments are resolved. For groups or service principals the user lookup
               fails (the error is saved in $errorz) and the row may show the previous user's UPN.
#>


$savePath = "" #folder to save user assignments
$errorz = @()

$roles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId 00000000-0000-0000-0000-000000000000
 foreach($item in $roles){
        
        $roleName = $null
        $roleID =$null
        $currentassignment = $null
        $obj = $null

        [string]$roleName = $item.DisplayName

        #New-Item "$savePath\$roleName.csv"

        $obj = @()

        [string]$roleID = $item.Id
        $currentassignment = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId "tenantID" -Filter "roleDefinitionId eq '$roleID'"    #FillInTenantID
            foreach($row in $currentassignment){
                 
                 try{$user = Get-AzureADUser -ObjectId $row.SubjectId}catch{
                      
                      $errorz += [PSCustomObject]@{ Error  =  $_ }
                      $_ = $null
                             }
                 $UPN = $user.UserPrincipalName
                 $AssignmentType = $row.AssignmentState
                 $obj += [PSCustomObject]@{ 
                           
                           RoleName = $roleName
		                   UserPrincipalName = $UPN
                           AssignmentType = $AssignmentType

		                   
}


                  }
        $obj | Export-Csv -Path "$savePath\$roleName.csv" -NoTypeInformation -Encoding UTF8
        
        }
