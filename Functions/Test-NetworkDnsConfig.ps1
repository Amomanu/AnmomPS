function Test-NetworkDnsConfig {
    <#
    .SYNOPSIS
        Checks IPv4/DNS settings based on ipconfig output and validates specific conditions.

    .DESCRIPTION
        Parses `ipconfig /all` to extract the active IPv4 address and DNS servers, then checks:
          - Both expected AnyCast DNS servers are present (defaults: 192.0.2.53, 192.0.2.54)
          - Loopback (127.0.0.1) is the 3rd DNS server (0-based index = 2)
          - The IPv4 address itself is NOT listed as a DNS server

        Returns a structured object with details and a summary message. Optionally writes
        human-readable status to the console with -Show.

    .PARAMETER ExpectedAnycast
        The DNS servers that must be present (default: 192.0.2.53, 192.0.2.54).

    .PARAMETER ExpectedLoopbackIndex
        Zero-based index where 127.0.0.1 should appear (default: 2 => "third" entry).

    .PARAMETER Show
        When specified, prints a summary and the DNS list to the console in addition to returning the object.

    .OUTPUTS
        PSCustomObject with:
          - IPv4
          - DnsServers
          - HasExpectedAnycast
          - LoopbackIndex
          - IPv4IsDnsServer
          - AllConditionsMet
          - Message

    .EXAMPLE
        Test-NetworkDnsConfig -Show

    .EXAMPLE
        Test-NetworkDnsConfig -ExpectedAnycast '1.1.1.1','8.8.8.8' -ExpectedLoopbackIndex 0
    #>
    [CmdletBinding()]
    param(
        [string[]]$ExpectedAnycast = @('192.0.2.53','192.0.2.54'),
        [int]$ExpectedLoopbackIndex = 2,
        [switch]$Show
    )

    # Run ipconfig /all and read output
    $ipconfig = ipconfig /all | Out-String

    # Extract IPv4 Address
    $ipv4Regex = 'IPv4 Address[ .]*:\s*([0-9.]+)'
    $ipv4Match = [regex]::Match($ipconfig, $ipv4Regex)
    $ipv4 = if ($ipv4Match.Success) { $ipv4Match.Groups[1].Value } else { $null }

    # Extract DNS Servers (first DNS section found)
    $dnsSection = ($ipconfig -split "DNS Servers[ .]*:" | Select-Object -Skip 1 | Select-Object -First 1)

    $dnsServers = @()
    if ($dnsSection) {
        $dnsServers = ($dnsSection -split "`r?`n") |
            Where-Object { $_ -match '^\s*[0-9.]+' } |
            ForEach-Object {
                # Trim and remove any trailing text like "(Preferred)"
                ($_.Trim() -replace '\s+\(.*$','')
            }
    }

    # Checks
    $hasAnycast = ($ExpectedAnycast | Where-Object { $dnsServers -contains $_ }).Count -eq $ExpectedAnycast.Count
    $loopbackIndex = $dnsServers.IndexOf('127.0.0.1')
    $ipv4IsDNS = if ($ipv4) { $dnsServers -contains $ipv4 } else { $false }

    $allOk = $hasAnycast -and ($loopbackIndex -eq $ExpectedLoopbackIndex) -and -not $ipv4IsDNS

    # Build message
    if ($allOk) {
        $message = "All conditions met: expected AnyCast DNS present ($($ExpectedAnycast -join ', ')), loopback is the $($ExpectedLoopbackIndex+1) DNS entry, and IPv4 address is not a DNS server. You can skip to the Change the Advanced Sharing Settings section."
    } else {
        $issues = @()
        if (-not $hasAnycast) { $issues += " - Expected AnyCast DNS servers missing ($($ExpectedAnycast -join ', '))." }
        if ($loopbackIndex -ne $ExpectedLoopbackIndex) { $issues += " - Loopback (127.0.0.1) is not the $($ExpectedLoopbackIndex+1) DNS entry." }
        if ($ipv4IsDNS) { $issues += " - IPv4 address is listed as a DNS server." }
        $message = "Conditions NOT met:`n" + ($issues -join "`n")
    }

    # Optional console output
    if ($Show) {
        if ($ipv4) { Write-Host "IPv4 Address: $ipv4" } else { Write-Host "IPv4 Address: (not found)" }
        Write-Host "DNS Servers:"
        if ($dnsServers.Count) {
            $dnsServers | ForEach-Object { Write-Host " $_" }
        } else {
            Write-Host " (none found)"
        }
        Write-Host ""
        Write-Host $message
    }

    # Return structured result
    [pscustomobject]@{
        IPv4               = $ipv4
        DnsServers         = $dnsServers
        HasExpectedAnycast = $hasAnycast
        LoopbackIndex      = $loopbackIndex
        IPv4IsDnsServer    = $ipv4IsDNS
        AllConditionsMet   = $allOk
        Message            = $message
    }
}
