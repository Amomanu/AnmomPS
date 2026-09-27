<#
.SYNOPSIS
    Writes all local groups and their members on a computer to a text file.
.DESCRIPTION
    For every local group, writes the group name and its members to C:\<computer name>.txt. Members are
    read with Get-LocalGroupMember; for the Administrators group the output of "net localgroup
    Administrators" is used instead. Groups without members, and groups whose members cannot be read,
    are skipped (except Administrators).
.NOTES
    Requires : administrator rights (it writes to the root of C:\) and Windows PowerShell 5.1
               (Get-LocalGroupMember).
#>


$hostname=hostname
$path = "C:\"+$hostname + ".txt"
$null>$path


(Get-LocalGroup).Name|ForEach-Object -Process {echo "$_"
                                        $temp=$_
                                        
                                        if ($temp -ne "Administrators")
                                            {try{
                                                $users = Get-LocalGroupMember $temp 
                                                if ($users -ne $null)
                                                {Add-Content -Value $temp -Path $path
                                                Add-Content -Value $users -Path $path
                                                }
                                            }
                                            catch{}
                                            }
                                            else {
                                                    try{
                                                    $users = net localgroup $temp
                                                    Add-Content -Value $temp -Path $path
                                                    Add-Content -Value $users -Path $path

                                                    }
                                                    catch{}
                                                    }
                                                        
                                        Clear-Variable temp
                                        Clear-Variable users}