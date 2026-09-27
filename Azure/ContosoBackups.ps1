<#
.SYNOPSIS
    Lists which Azure VMs in a dev and a prod subscription are protected by Azure Backup.
.DESCRIPTION
    Switches to the dev subscription and then to the prod subscription and, for every VM, calls
    Get-AzRecoveryServicesBackupStatus. For VMs that are backed up, the VM name and its backup status are
    added to $result under a "DEV" or "Prod" marker. VMs that are not backed up are skipped.
.NOTES
    Requires : Az.Compute and Az.RecoveryServices modules; run Connect-AzAccount first.
    Setup    : set the two subscription IDs in the Set-AzContext lines.
    Output   : results stay in the $result variable (nothing is printed or exported) - show them with
               $result after the run.
#>


$result = @()
$status = @()

Set-AzContext -SubscriptionId 22222222-2222-2222-2222-222222222222  #DevSubscription
$result+="DEV"

#$i = 0
#$j = 0
$VMs = Get-AzVM
foreach($VM in $VMs){
    $name = $VM.Name
    $status = Get-AzRecoveryServicesBackupStatus -ResourceGroupName $VM.ResourceGroupName -Name $name -Type AzureVM
    if($status.BackedUp -eq "True"){
        $result+= $name
        $result+= $status 
        #$i++
        }else{#$j++
        }
    }

Set-AzContext -SubscriptionId 33333333-3333-3333-3333-333333333333  #ProdSubscription
$result+="Prod"
$VMs = Get-AzVM
foreach($VM in $VMs){
    $name = $VM.Name
    $status = Get-AzRecoveryServicesBackupStatus -ResourceGroupName $VM.ResourceGroupName -Name $name -Type AzureVM
    if($status.BackedUp -eq "True"){
        $result+= $name
        $result+= $status 
        #$i++
        }else{#$j++
        }
    }

