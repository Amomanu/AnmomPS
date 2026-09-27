<#
.SYNOPSIS
    Test copy of Microsoft Teams from one tenant to another with ShareGate; each copy gets a "-Test"
    suffix.
.DESCRIPTION
    Unloads the MicrosoftTeams module (both it and ShareGate have a Get-Team cmdlet), imports ShareGate,
    reads team names from the DisplayName column of $csvFile, connects to the source and destination
    tenants (browser sign-in, SharePoint admin URLs) and, for each team, runs ShareGate Copy-Team with
    the title "<team name>-Test". Intended for teams without private channels.
.NOTES
    Requires : ShareGate Desktop with its PowerShell module (licensed).
    Setup    : set $csvFile and the two SharePoint admin URLs. Remove the "-Test" suffix for the real
               migration.
#>


#Migrate Teams with No Private Channels

#Import ShareGate Module
Remove-Module MicrosoftTeams -ErrorAction SilentlyContinue
Import-Module ShareGate


#Import CSV file of 25-50 Teams for Migration
$csvFile = "C:\Script\TeamsMigraitonList.csv"
$table = Import-Csv $csvFile -Delimiter ","



#Connect to Source and Destitaiton Tenants
$sourcetenant = Connect-Tenant -Domain https://litware-admin.sharepoint.com -Browser
$destinationtenant = Connect-Tenant -Domain https://proseware-admin.sharepoint.com -Browser

#For each Team in the .csv Migrate Team from Litware to Proseware

foreach ($row in $table) { 

    #Copy teams with new name with Test for Testing.
    $TeamName = $row.DisplayName 
    $TestTeamName = $TeamName + "-Test"
    $team =  Get-Team -Name  $TeamName  -Tenant $sourcetenant
    Copy-Team -Team $team -TeamTitle $TestTeamName  -DestinationTenant $destinationtenant

}