<#
.SYNOPSIS
    Runs a local PowerShell script on every Windows VM in every subscription you can access.
.DESCRIPTION
    Loops through all subscriptions (Get-AzSubscription) and all VMs. It builds an OS string from the VM
    image Offer and Sku; for VMs whose string contains "Win" it is meant to run
    C:\Scripts\GetLastComputerLogin.ps1 on the VM with Invoke-AzVMRunCommand and print the result. The
    branch meant for Linux VMs is a placeholder that runs the same Windows command.
.NOTES
    Requires : Az.Compute module; run Connect-AzAccount first.
    Setup    : set -ScriptPath to the script you want to run.
    Known issues: the closing brace of the else-branch is inside the comment on the same line, so the
    script does not parse as-is. Fixing that is not enough: both Invoke-AzVMRunCommand calls use
    -CommandId "RunPowerShellScriptWindows", which is not a valid Run Command ID - for Windows VMs it must
    be "RunPowerShellScript" (Linux: "RunShellScript"), otherwise every call fails. VMs created from
    custom images may have no image Offer/Sku and would be treated as non-Windows.
#>


$subs=Get-AzSubscription
foreach($obj in $subs)
    {$currentSubscription = $obj.SubscriptionId
    $currentSubscription
        Set-AzContext -SubscriptionId $currentSubscription |Out-Null
        $VMS=Get-azvm | Select-Object -Property ResourceGroupName,Name,StorageProfile
            foreach($row in $VMS)
                {
                 $osver = $row.StorageProfile.ImageReference.Offer + " $($row.StorageProfile.ImageReference.Sku)"|Out-String
                 #Write-Output  "$row.Name | $row.ResourceGroupName | $osver " 
                                  
                 $output= $row.Name + $row.ResourceGroupName + $osver
                 $stringOS=$osver|Out-String
                 #$output
                 if($stringOS -like "*Win*")
                    { $osver

                   Invoke-AzVMRunCommand -ResourceGroupName $row.ResourceGroupName -VMName $row.Name -CommandId "RunPowerShellScriptWindows" -ScriptPath "C:\Scripts\GetLastComputerLogin.ps1"   #Add Win Only script
                    }
                    else
                        {Invoke-AzVMRunCommand -ResourceGroupName $row.ResourceGroupName -VMName $row.Name -CommandId "RunPowerShellScriptWindows" -ScriptPath "C:\Scripts\GetLastComputerLogin.ps1"   #Add linux Only script}
                }
        


    }

