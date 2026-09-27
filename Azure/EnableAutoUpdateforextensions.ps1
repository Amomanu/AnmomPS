<#
.SYNOPSIS
    Enables automatic upgrade on every VM extension in the current subscription that does not have it.
.DESCRIPTION
    For each VM (Get-AzVM) it lists the extensions and, for each extension whose EnableAutomaticUpgrade is
    not true, runs Set-AzVMExtension -EnableAutomaticUpgrade $true with the extension's publisher, type
    and name. Failures are shown on screen as normal PowerShell errors.
.NOTES
    Requires : Az.Compute module; connect and select the subscription first (the Connect-AzAccount and
               Set-AzContext lines at the top are commented out).
    Note     : not every extension supports automatic upgrade - those attempts fail with an error on
               screen. Set-AzVMExtension is called without the extension's settings, so test on one VM
               first.
    Known issue: Azure failures are not written to C:\A\errors.txt. Az cmdlets report them as
    non-terminating errors and Set-AzVMExtension is called without -ErrorAction Stop, so the try/catch
    (with its red message and log line) never runs for them. Add -ErrorAction Stop to the
    Set-AzVMExtension call to enable the logging (the folder C:\A must exist).
#>


#Connect-AzAccount
#Set-AzContext -Subscriptionid 22222222-2222-2222-2222-222222222222 #dev subs

$vms = get-azvm

foreach($vm in $vms){

    #nulling out variables

    $vmName=$null
    $vmRG=$null
    $VMExtension = $null
    $automaticUpgrade = $null
    $publisher = $null

    #getting VMs

    $vmName=$vm.Name
    $vmRG=$vm.ResourceGroupName
    #getting extensions per VM
    $VMExtension = Get-AzVMExtension -ResourceGroupName $vmRG -VMName $vmName
    

    foreach($extension in $VMExtension){
        $automaticUpgrade = $null
        $publisher = $null
        $extensionType = $null



        $automaticUpgrade  = $extension.EnableAutomaticUpgrade
        $publisher = $extension.Publisher
        $extensionType = $extension.ExtensionType
        $extensionName = $extension.Name
        #$extension.Name
        if($automaticUpgrade -ne $true){
                 Write-Host -BackgroundColor DarkRed -ForegroundColor Yellow "Attempting to enable auto-update for the extensions $extensionName for vm $vmName in resource group $vmRG"
                 try{                    
                    Set-AzVMExtension -Publisher $publisher -ExtensionType $extensionType -EnableAutomaticUpgrade $true -VMName $vmName -ResourceGroupName $vmRG -Name $extensionName
                    }catch{
                        IF($_){
                            Write-host -BackgroundColor Black -ForegroundColor Red "Could not enable auto-update for extension $extensionName because $_ "
                            $_ | Out-String| Out-File -FilePath "C:\A\errors.txt" -NoClobber -Append -Force
                            }
                            $_ = $null
                        }
            }
        
        
        }

    }