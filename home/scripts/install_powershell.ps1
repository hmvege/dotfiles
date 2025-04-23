$LatestVersion = '7.5.0'
$MinVersion = '7.4.0'

$InstallerUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$LatestVersion/PowerShell-$LatestVersion-win-x64.msi"
$InstallerPath = "$env:TEMP\PowerShell-$LatestVersion.msi"

# SHA-256 for PowerShell-7.5.0-win-x64.msi (from Microsoft’s release checksums)
$ExpectedHash = '6B988B7E236A8E1CF1166D3BE289D3A20AA344499153BDAADD2F9FEDFFC6EDA9'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# .NET-based SHA256 hasher (cross-platform safe)
function Get-SHA256Hash {
    param([string]$Path)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hashBytes = $sha256.ComputeHash($stream)
        return ([BitConverter]::ToString($hashBytes)).Replace('-','').ToUpper()
    }
    finally {
        $stream.Close()
    }
}

function Install-PowerShell {
    Write-Host "Downloading PowerShell $LatestVersion..."
    curl.exe -fSL $InstallerUrl -o $InstallerPath

    Write-Host 'Verifying hash...'
    $ActualHash = Get-SHA256Hash $InstallerPath
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item $InstallerPath -Force
        throw "HASH MISMATCH! Expected $ExpectedHash got $ActualHash"
    }

    Write-Host 'Hash OK - installing...'
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$InstallerPath`" /qn /norestart"
    Remove-Item $InstallerPath -Force
    Write-Host "PowerShell $LatestVersion installed."
}

# Try to find an existing pwsh.exe
$pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue

if (-not $pwshCmd) {
    Write-Host "No PowerShell detected - installing $LatestVersion."
    Install-PowerShell
    return
}

# Parse the current version
$currString = & $pwshCmd.Source -NoLogo -Command '$PSVersionTable.PSVersion.ToString()'
[Version] $current = $currString
[Version] $min = $MinVersion

Write-Host "Detected PowerShell $current (minimum allowed: $min)"

if ($current -lt $min) {
    Write-Host "Version $current is older than $min - installing $LatestVersion."
    Install-PowerShell
}
else {
    Write-Host "Version $current >= $min - skipping installation."
}
