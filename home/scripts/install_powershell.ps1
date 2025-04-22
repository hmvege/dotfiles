$LatestVersion = '7.5.0'
$InstallerUrl  = "https://github.com/PowerShell/PowerShell/releases/download/v$LatestVersion/PowerShell-$LatestVersion-win-x64.msi"
$InstallerPath = "$env:TEMP\PowerShell-$LatestVersion.msi"

# SHA‑256 for PowerShell‑7.5.0‑win‑x64.msi - from Microsoft’s release checksums
$ExpectedHash  = '6B988B7E236A8E1CF1166D3BE289D3A20AA344499153BDAADD2F9FEDFFC6EDA9'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-PowerShell {
    Write-Host "Downloading PowerShell $LatestVersion..."
    curl.exe -fSL $InstallerUrl -o $InstallerPath

    Write-Host 'Verifying hash...'
    Import-Module Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue
    $ActualHash = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash.ToUpper()
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item $InstallerPath -Force
        throw "HASH MISMATCH!  expected $ExpectedHash  got $ActualHash"
    }

    Write-Host 'Hash OK - installing'
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$InstallerPath`" /qn /norestart"
    Remove-Item $InstallerPath -Force
    Write-Host "PowerShell $LatestVersion installed."
}

# ---------- main ----------
$Pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if (-not $Pwsh) {
    Write-Host 'PowerShell not found - installing.'
    Install-PowerShell
}
else {
    $Current = & $Pwsh.Source -NoLogo -Command '$PSVersionTable.PSVersion.ToString()'
    if ($Current -ne $LatestVersion) {
        Write-Host "Updating PowerShell $Current → $LatestVersion."
        Install-PowerShell
    }
    else {
        Write-Host "PowerShell $LatestVersion already present - nothing to do."
    }
}