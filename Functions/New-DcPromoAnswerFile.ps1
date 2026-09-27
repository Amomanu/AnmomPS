function New-DcPromoAnswerFile {
<#
.SYNOPSIS
  Generate a DCPROMO unattended answer file.

.DESCRIPTION
  Builds a file containing all DCPROMO keys and values. Prompts securely for the
  domain credential password and DSRM password if they’re not provided as SecureString.
  The file is written as ASCII for compatibility (Server 2008/2008 R2 dcpromo.exe).

.PARAMETER Username
  User name used by DCPROMO (e.g., Administrator).

.PARAMETER Domain
  DNS name of the domain (e.g., corp.contoso.com).

.PARAMETER Password
  SecureString for the domain credential password. If omitted, the function prompts.

.PARAMETER SafeModeAdminPassword
  SecureString for DSRM (Directory Services Restore Mode) password. If omitted, prompts.

.PARAMETER SiteName
  AD site name. No default—must be specified if needed.

.PARAMETER ReplicaOrNewDomain
  One of: replica, readOnlyReplica, newForest, newDomain. Default: replica.

.PARAMETER ReplicaDomainDNSName
  DNS name of replica target domain. Defaults to -Domain if omitted.

.PARAMETER DatabasePath
  NTDS database path. Default: N:\NTDS

.PARAMETER LogPath
  NTDS log path. Default: N:\LOGS

.PARAMETER SYSVOLPath
  SYSVOL path. Default: S:\SYSVOL

.PARAMETER InstallDNS
  yes|no. Default: yes

.PARAMETER ConfirmGC
  yes|no. Default: yes

.PARAMETER RebootOnCompletion
  yes|no. Default: yes

.PARAMETER OutputPath
  Path to the answer file. Default: .\dcpromo-unattend.txt

.PARAMETER NoPrompt
  If set, the function will NOT prompt for missing passwords.

.PARAMETER PassThru
  If set, returns an object with Path and Content.
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter()]
        [System.Security.SecureString]$Password,

        [Parameter()]
        [System.Security.SecureString]$SafeModeAdminPassword,

        [Parameter()]
        [string]$SiteName,  # No default

        [Parameter()]
        [ValidateSet('replica','readOnlyReplica','newForest','newDomain')]
        [string]$ReplicaOrNewDomain = 'replica',

        [Parameter()]
        [string]$ReplicaDomainDNSName,

        [Parameter()]
        [string]$DatabasePath = 'N:\NTDS',

        [Parameter()]
        [string]$LogPath = 'N:\LOGS',

        [Parameter()]
        [string]$SYSVOLPath = 'S:\SYSVOL',

        [Parameter()]
        [ValidateSet('yes','no')]
        [string]$InstallDNS = 'yes',

        [Parameter()]
        [ValidateSet('yes','no')]
        [string]$ConfirmGC = 'yes',

        [Parameter()]
        [ValidateSet('yes','no')]
        [string]$RebootOnCompletion = 'yes',

        [Parameter()]
        [string]$OutputPath = '.\dcpromo-unattend.txt',

        [Parameter()]
        [switch]$NoPrompt,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        function ConvertTo-PlainText {
            param([Parameter(Mandatory)][System.Security.SecureString]$SecureText)
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureText)
            try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
            finally {
                if ($bstr -ne [IntPtr]::Zero) {
                    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
            }
        }
    }

    process {
        if (-not $Password) {
            if ($NoPrompt) { throw "Password was not provided and prompting is disabled (-NoPrompt)." }
            $Password = Read-Host "Enter domain credential password for $Domain\$Username" -AsSecureString
        }
        if (-not $SafeModeAdminPassword) {
            if ($NoPrompt) { throw "SafeModeAdminPassword was not provided and prompting is disabled (-NoPrompt)." }
            $SafeModeAdminPassword = Read-Host "Enter DSRM (Safe Mode) Administrator password" -AsSecureString
        }

        if (-not $ReplicaDomainDNSName) {
            $ReplicaDomainDNSName = $Domain
            Write-Verbose "ReplicaDomainDNSName not specified. Defaulting to Domain: $ReplicaDomainDNSName"
        }

        $PasswordPlain = ConvertTo-PlainText -SecureText $Password
        $SafeModePlain = ConvertTo-PlainText -SecureText $SafeModeAdminPassword

        $settings = [ordered]@{
            'UserName'               = $Username
            'UserDomain'             = $Domain
            'Password'               = $PasswordPlain
        }

        if ($SiteName) { $settings['SiteName'] = $SiteName }

        $settings['ReplicaOrNewDomain']    = $ReplicaOrNewDomain
        $settings['ReplicaDomainDNSName']  = $ReplicaDomainDNSName
        $settings['DatabasePath']          = $DatabasePath
        $settings['LogPath']               = $LogPath
        $settings['SYSVOLPath']            = $SYSVOLPath
        $settings['InstallDNS']            = $InstallDNS
        $settings['ConfirmGC']             = $ConfirmGC
        $settings['SafeModeAdminPassword'] = $SafeModePlain
        $settings['RebootOnCompletion']    = $RebootOnCompletion

        # Build lines with [DCINSTALL] header first
        $content = @('[DCINSTALL]')
        $content += $settings.GetEnumerator() | ForEach-Object {
            '{0}={1}' -f $_.Key, $_.Value
        }

        $dir = Split-Path -Path $OutputPath -Parent
        if ($dir -and -not (Test-Path $dir)) {
            Write-Verbose "Creating directory: $dir"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }

        if ($PSCmdlet.ShouldProcess($OutputPath, "Write DCPROMO answer file")) {
            $content | Out-File -FilePath $OutputPath -Encoding ASCII -Force
            Write-Verbose "Wrote DCPROMO unattended file to: $OutputPath"
        }

        if ($PassThru) {
            [PSCustomObject]@{
                Path    = (Resolve-Path $OutputPath).Path
                Content = $content -join [Environment]::NewLine
            }
        }
    }
}
