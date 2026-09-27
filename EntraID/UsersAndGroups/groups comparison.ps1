<#
.SYNOPSIS
    Lists the members of one Azure AD group that are not members of a second group.
.DESCRIPTION
    Reads all members of $FirstGroupID and, for each one, checks whether it is also a member of
    $SecondGroupID. Members missing from the second group are printed as "member <display name> not
    found".
.NOTES
    Requires : AzureAD module and Connect-AzureAD.
    Setup    : set $FirstGroupID and $SecondGroupID (group object IDs).
    Known issue: the second group is read without -All $true, so only its first 100 members are
    checked - members beyond that are reported as "not found". The second group is read again for every
    member, which is slow for large groups.
#>


#Connect-AzureAD
$FirstGroupID = "44444444-4444-4444-4444-444444444441"
$FirstGroupMembers = Get-AzureADGroupMember -ObjectId $FirstGroupID -All $true
$SecondGroupID = "44444444-4444-4444-4444-444444444442"
foreach($user in $FirstGroupMembers){
    $UserDisplayName = $null
    $UserUPN = $null
    $UserObjectID = $null
    $FirstGroupID = $null

    $UserUPN = $user.UserPrincipalName
    $UserObjectID = $user.ObjectId
    $UserDisplayName = $user.DisplayName
    
    $FoundUser = Get-AzureADGroupMember -ObjectId $SecondGroupID | Where-Object {$_.ObjectID -eq $UserObjectID}  
     if($FoundUser){  
        #Write-Host ('member ' + ($UserDisplayName) + ' found')
            }else{  
                Write-Host ('member ' + ($UserDisplayName) + ' not found')
                 }  
    }




