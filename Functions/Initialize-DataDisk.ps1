function Initialize-DataDisk {
<#
.SYNOPSIS
    Initializes a RAW disk, creates one partition, formats it, and assigns a drive letter.

.DESCRIPTION
    - Only operates on RAW (uninitialized) disks to avoid accidental data loss.
    - Initializes as GPT by default (MBR optional).
    - Creates one partition using specified or all space.
    - Formats (NTFS/ReFS) with a label and allocation unit size.
    - Assigns the requested drive letter (fails if already in use).
    - Returns a summary object.

.PARAMETER DiskNumber
    Target disk number (from Get-Disk).

.PARAMETER DriveLetter
    Desired drive letter (single letter, e.g. 'N').

.PARAMETER Label
    Volume label (e.g., 'NTDS').

.PARAMETER PartitionStyle
    'GPT' (default) or 'MBR'.

.PARAMETER FileSystem
    'NTFS' (default) or 'ReFS'.

.PARAMETER AllocationUnitSize
    Cluster size in bytes (default 512).

.PARAMETER PartitionSizeGB
    Optional. Size of the partition in GB. If not specified, uses all available space.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position=0)]
        [ValidateRange(0, 9999)]
        [int]$DiskNumber,

        [Parameter(Mandatory, Position=1)]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory, Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,

        [ValidateSet('GPT','MBR')]
        [string]$PartitionStyle = 'GPT',

        [ValidateSet('NTFS','ReFS')]
        [string]$FileSystem = 'NTFS',

        [int]$AllocationUnitSize = 512,

        [int]$PartitionSizeGB
    )

    begin {
        $DriveLetter = $DriveLetter.ToUpper()
    }

    process {
        try {
            $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop

            if ($disk.PartitionStyle -ne 'RAW') {
                throw "Disk $DiskNumber is '$($disk.PartitionStyle)', not RAW. Refusing to proceed to avoid data loss."
            }

            if (Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -eq $DriveLetter }) {
                throw "Drive letter '$($DriveLetter):' is already in use."
            }

            if ($PSCmdlet.ShouldProcess("Disk $DiskNumber", "Initialize as $PartitionStyle")) {
                Initialize-Disk -Number $DiskNumber -PartitionStyle $PartitionStyle -ErrorAction Stop
            }

            # Create partition with specified size or maximum size
            if ($PSCmdlet.ShouldProcess("Disk $DiskNumber", "Create partition")) {
                if ($PartitionSizeGB) {
                    $sizeBytes = $PartitionSizeGB * 1GB
                    $part = New-Partition -DiskNumber $DiskNumber -Size $sizeBytes -AssignDriveLetter -ErrorAction Stop
                } else {
                    $part = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
                }
            }

            if ($PSCmdlet.ShouldProcess("Partition $($part.PartitionNumber) on Disk $DiskNumber", "Format $FileSystem, Label '$Label', AUS $AllocationUnitSize")) {
                $vol = Format-Volume -Partition $part -FileSystem $FileSystem -NewFileSystemLabel $Label `
                                     -AllocationUnitSize $AllocationUnitSize -Force -Confirm:$false -ErrorAction Stop
            }

            if ($vol.DriveLetter -ne $DriveLetter) {
                if ($PSCmdlet.ShouldProcess("Volume '$Label'", "Change drive letter from $($vol.DriveLetter) to $DriveLetter")) {
                    Set-Partition -DriveLetter $vol.DriveLetter -NewDriveLetter $DriveLetter -ErrorAction Stop
                }
            }

            $final = Get-Volume -FileSystemLabel $Label -ErrorAction Stop
            [pscustomobject]@{
                DiskNumber         = $DiskNumber
                PartitionStyle     = $PartitionStyle
                PartitionNumber    = $part.PartitionNumber
                DriveLetter        = $DriveLetter
                Label              = $Label
                FileSystem         = $FileSystem
                AllocationUnitSize = $AllocationUnitSize
                SizeGB             = [math]::Round($final.Size/1GB, 2)
                HealthStatus       = $disk.HealthStatus
                OperationalStatus  = $disk.OperationalStatus -join ', '
                Action             = 'Created'
            }
        }
        catch {
            Write-Error $_
        }
    }
}
