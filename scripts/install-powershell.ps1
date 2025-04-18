{{ if eq .chezmoi.os "windows" }}
# File: scripts/install-powershell.ps1.tmpl

$latestVersion = '7.4.1'
$pwshPath = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)?.Source

function Install-PowerShell {
    Write-Output "Installing PowerShell $latestVersion..."

    $installerUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$latestVersion/PowerShell-$latestVersion-win-x64.msi"
    $installerPath = "$env:TEMP\PowerShell-$latestVersion.msi"

    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    Start-Process msiexec.exe -ArgumentList "/i $installerPath /qn" -Wait
    Remove-Item $installerPath -Force

    Write-Output "PowerShell $latestVersion installed successfully."
}

if (-not $pwshPath) {
    Write-Output "PowerShell not found. Proceeding to install."
    Install-PowerShell
} else {
    $currentVersion = (& $pwshPath -NoLogo -Command '$PSVersionTable.PSVersion.ToString()')
    if ($currentVersion -ne $latestVersion) {
        Write-Output "PowerShell version $currentVersion detected. Updating to $latestVersion."
        Install-PowerShell
    } else {
        Write-Output "PowerShell $latestVersion is already installed."
    }
}
{{ end }}
