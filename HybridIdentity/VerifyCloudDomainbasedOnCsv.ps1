<#
.SYNOPSIS
    Lists the users in a migration list whose cloud UPN is not on the expected domain.
.DESCRIPTION
    For each UPN in the TargetUPN column of $import it reads the Azure AD user and exports the UPNs whose
    domain part is not "fabrikam.com" to $Exportpath.
.NOTES
    Requires : AzureAD module and Connect-AzureAD.
    Setup    : set $import, $Exportpath and the domain name in the if-statement.
    Note     : users that cannot be found in Azure AD produce an error.
#>


#Connect-AzureAD
$import="C:\Temp\Fabrikam\MigrationList\WGB\WGBFinalList.csv"
$Exportpath = "C:\Temp\Fabrikam\MigrationList\WGB\Usersnotonfabrikam.csv"
$file=Import-Csv -Path $import
$upns=$file.TargetUPN

$notonfabrikam = @()

foreach($row in $upns){$user=Get-AzureADUser -ObjectId $row
                       $upn=$user.UserPrincipalName
                       #$upn
                       echo '---'
                       
                       
                       $split=$upn -split  '@'
                       $domain = $split[1]
                       $domain
                       if($domain -notcontains 'fabrikam.com'){
                              $notonfabrikam += [PSCustomObject]@{ UserPrincipalName = $upn	                       
                                }
                            #$upn|Export-CSV -Path $Exportpath -Append -NoTypeInformation
                            }
                            #>
                        }

                        $notonfabrikam | Export-Csv -Path $Exportpath -NoTypeInformation
