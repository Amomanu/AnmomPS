<#
.SYNOPSIS
    Copies OneDrive "Documents" libraries between two tenants with ShareGate (full copy).
.DESCRIPTION
    Reads source and destination site URLs from $csvFile (columns SourceSite and DestinationSite). For
    each row it connects to both sites with ShareGate (Connect-Site) using the admin accounts in the
    script, copies the "Documents" library with Copy-Content, then removes the migration account's site
    collection administrator rights on both sites (Remove-SiteCollectionAdministrator).
.NOTES
    Requires : ShareGate Desktop with its PowerShell module (licensed).
    Setup    : set $csvFile and the source/destination user names and passwords. User name + password
               sign-in does not work for accounts with MFA.
    See also : "migrationscript - incrememntal.ps1" does the same with incremental copy settings, for
               later delta passes.
#>


Import-Module Sharegate
$csvFile = "C:\CSV\CopyContent.csv"
$table = Import-Csv $csvFile -Delimiter ","

$srcUsername = "sharegateadmin@fourthcoffee.onmicrosoft.com"
$srcPassword = ConvertTo-SecureString "<SOURCE_PASSWORD>" -AsPlainText -Force

$dstUsername = "sharegateadmin@relecloud.onmicrosoft.com"
$dstPassword = ConvertTo-SecureString "<DESTINATION_PASSWORD>" -AsPlainText -Force

Set-Variable srcSite, dstSite, srcList, dstList
foreach ($row in $table) {
    Clear-Variable srcSite
    Clear-Variable dstSite
    Clear-Variable srcList
    Clear-Variable dstList
    $st=$row.SourceSite
    echo $st
    echo "-----"
    echo $row.DestinationSite
    echo "-----"
    $srcSite = Connect-Site -Url $st -Username $srcUsername -Password $srcPassword
    $dstSite = Connect-Site -Url $row.DestinationSite -Username $dstUsername -Password $dstPassword -Verbose
    $srcList = Get-List -Site $srcSite -Name "Documents"
    $dstList = Get-List -Site $dstSite -Name "Documents"
    Copy-Content -SourceList $srcList -DestinationList $dstList
    Remove-SiteCollectionAdministrator -Site $srcSite
    Remove-SiteCollectionAdministrator -Site $dstSite
}
