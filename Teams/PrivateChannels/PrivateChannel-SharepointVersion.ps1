<#
.SYNOPSIS
    Lists all Teams private channels from SharePoint Online (one site per private channel) into a CSV.
.DESCRIPTION
    Connects to the SharePoint admin URL, gets all sites that use the private-channel template
    TEAMCHANNEL#0 and writes TeamDisplayName, PrivateChannelName, Owner, URL and OriginalTitle to
    C:\a\teams.csv. The team and channel names are taken from the site title ("<team> - <channel>"),
    split at the first "-".
.NOTES
    Requires : SharePoint Online Management Shell.
    Setup    : set the admin URL in Connect-SPOService and the output path (the folder must exist).
    Note     : team names that contain "-" are split incorrectly - check the OriginalTitle column.
#>


$pathlog = "C:\a\teams.csv"



Connect-SPOService -Url https://litware-admin.sharepoint.com/   #connect to litware spo


$sites=get-SPOSite -Limit All -Template "TEAMCHANNEL#0" |Select-Object Title , Url , Owner    #loads data needed in variable

New-Item C:\a\teams.csv -ItemType File        #Creates new file
Set-Content C:\a\teams.csv 'TeamDisplayName,PrivateChannelName,Owner,URL,OriginalTitle'    #Adds header to csv
foreach ($site in $sites)         
    {$title= $site.Title
    $owner=$site.Owner
    $url=$site.Url
    $a,$b = $title.split('-',2)
    if ($b -like "-*")                        #if $b starts with - , it removes it
    {
    $b=$b -replace ".*-"
         }

    Add-content $pathlog -Value "`"$a`",`"$b`",`"$owner`",`"$url`",`"$title`""    #wites to CSV
  
        }



