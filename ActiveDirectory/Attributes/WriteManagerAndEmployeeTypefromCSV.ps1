<#
.SYNOPSIS
    Sets manager and employeeType in AD from a CSV that identifies users by objectGUID.
.DESCRIPTION
    For each row with an ObjectId value, finds the user in AD by objectGUID (ObjectId column) and the
    manager by objectGUID (ManagerObjectId column) on $server, sets the user's manager to the manager's
    distinguished name and, when the EmployeeType column has a value, writes employeeType. Errors, and
    users not found in AD (reported as "No ObjectID in file"), are collected in $log and printed at the end.
.NOTES
    Requires : ActiveDirectory module.
    Setup    : set $server (currently "***") and the Import-Csv path. ObjectId and ManagerObjectId must
               be the on-prem objectGUIDs.
    Note     : the EmployeeHireDate column is read but not written. The Set-ADUser calls do not use
               $server.
#>


$server = "***"

$CSV=Import-Csv -Path "C:\SetManager\Set-ManagerTake1.csv" 
$log = @()

foreach($row in $CSV){


    $UserADObject = $null
    $Usermanager = $null
    $employeeType = $null
    $employeeHireDate = $null


    $UserObjectId=$row.ObjectId 
    $employeeType = $row.EmployeeType
    $employeeHireDate = $row.EmployeeHireDate

    if($UserObjectId){
    #if($UserObjectId -eq "55555555-5555-5555-5555-555555555553"){

    $ManagerObjectId= $Row.ManagerObjectId

    try{$UserADObject = Get-ADUser -filter {ObjectGUID -eq $UserObjectId} -Properties * -Server $server
    }catch{$log+=$_
        }
    if($UserADObject){
    #$UserADObject
    try{$UserManager = Get-ADUser -filter {ObjectGUID -eq $ManagerObjectId} -Properties * -Server $server
    }catch{$log+=$_
    }
    if($Usermanager){
    try{Set-ADUser -Identity $UserADObject.samaccountname -Manager $UserManager.distinguishedName
    }catch{$log+=$_
    }
        }
    if($employeeType){
        try{Set-ADUser -Identity $UserADObject.samaccountname  -Replace @{employeeType = $employeeType }
        }catch{$log+=$_
        }
        } 
    }else{Write-Host -ForegroundColor Red "No ObjectID in file"
        $log += "No ObjectID in File"}
#}
}
}

If($log){
    $log
    }
