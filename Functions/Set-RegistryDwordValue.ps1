function Set-RegistryDwordValue {
<#
.SYNOPSIS
    Creates or updates a DWORD registry value, creating the key if needed.

.PARAMETER RegPath
    Registry path (e.g., HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System)

.PARAMETER RegName
    Registry value name (e.g., InactivityTimeoutSecs)

.PARAMETER DesiredValue
    Desired DWORD value (0..0xFFFFFFFF)

.OUTPUTS
    PSCustomObject with Path, Name, OldValue, NewValue, Action, KeyCreated.
    
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$RegPath,

        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$RegName,

        [Parameter(Mandatory, Position=2)]
        #[ValidateRange(0,0xFFFFFFFF)]
        [uint32]$DesiredValue
    )

    $action = "Unchanged"
    $oldValue = $null
    $keyCreated = $false

    try {
        # Ensure the key exists (create if missing)
        if (-not (Test-Path -LiteralPath $RegPath)) {
            if ($PSCmdlet.ShouldProcess($RegPath, "Create registry key")) {
                New-Item -Path $RegPath -Force | Out-Null
                $keyCreated = $true
            }
        }

        # Try to get the existing property
        $existing = Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue

        if ($null -eq $existing) {
            # Property missing -> create it
            if ($PSCmdlet.ShouldProcess("$RegPath\$RegName", "Create DWORD with value $DesiredValue")) {
                New-ItemProperty -Path $RegPath -Name $RegName -PropertyType DWORD -Value $DesiredValue -Force | Out-Null
                $action = "Created"
            }
        }
        else {
            # Property exists -> update only if different
            $currentValue = [uint32]$existing.$RegName
            $oldValue = $currentValue

            if ($currentValue -ne $DesiredValue) {
                if ($PSCmdlet.ShouldProcess("$RegPath\$RegName", "Update DWORD from $currentValue to $DesiredValue")) {
                    Set-ItemProperty -Path $RegPath -Name $RegName -Value $DesiredValue
                    $action = "Updated"
                }
            }
            else {
                $action = "Unchanged"
            }
        }

        # Return a structured summary
        [pscustomobject]@{
            Path       = $RegPath
            Name       = $RegName
            OldValue   = $oldValue
            NewValue   = $DesiredValue
            Action     = $action
            KeyCreated = $keyCreated
        }
    }
    catch {
        Write-Error $_
    }
}
