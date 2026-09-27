<#
.SYNOPSIS
    Sets the AD mail attribute for the users listed in a CSV.
.DESCRIPTION
    For each row in $importfile, sets the mail attribute (Set-ADUser -EmailAddress) of the AD user named
    in the SAM column to the value in the Mail column. Accepts the output of Get-mail-for-users-onList.ps1.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $importfile.
    Note     : there is no logging or error handling.
#>


$importfile= "C:\SMTPExports\TST\mailexport.csv"
$mails= Import-Csv -Path $importfile
foreach($row in $mails){
    $sam=$row.SAM
    Set-ADUser -Identity $row.SAM -EmailAddress $row.Mail
    }
