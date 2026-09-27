<#
.SYNOPSIS
    Makes every member of the listed teams an owner (for example for teams that have no owner).
.DESCRIPTION
    Installs and imports the MicrosoftTeams module, connects, reads team names from the GroupName column
    of $csvFile and, for each team, adds every current member as owner (Add-TeamUser -Role Owner). Each
    change is logged to $logfilepath.
.NOTES
    WARNING  : all members of each listed team become owners - limit the input list to the teams that
               really need owners.
    Requires : rights to install modules (Install-Module -Force reinstalls MicrosoftTeams on every run).
    Setup    : set $csvFile and $logfilepath.
#>


$csvFile = "C:\Teamsscripts\Owners\NoOwners.csv"
$table = Import-Csv $csvFile -Delimiter ","

$logfilepath = "C:\Teamsscripts\Owners\NoOwners.txt"

install-module MicrosoftTeams -Force
Import-Module MicrosoftTeams

Connect-MicrosoftTeams

foreach ($row in $table) {
	$team=get-team -displayName $row.GroupName
	$teamO = Get-teamUser -GroupId $team.GroupId|Select-Object User 
	foreach ($User in $teamO)
			{
				$User = $User.User | Out-String	
				Add-TeamUser -GroupId $team.GroupId -User $User -Role Owner
				$CurrentTeam=Get-team -GroupId $team.GroupId |Select-Object DisplayName
				$v1=echo "Added" $User "as owner to team" $CurrentTeam.DisplayName
				$v=echo "-------------------------------------------------------"
				Add-Content $logfilepath $v1
				echo "Added" $User "as owner to team" $CurrentTeam.DisplayName
				echo "-------------------------------------------------------"
				clear-variable -Name "User"
			}
	}

