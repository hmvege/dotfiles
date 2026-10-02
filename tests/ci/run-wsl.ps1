<#
.SYNOPSIS
Import Ubuntu WSL and run the existing preparation and installation checks.
The workflow unregisters the distribution in its always-run cleanup step.
#>
param(
        [string]$Mode,
        [string]$Lite,
        [string]$Source,
        [string]$TempDirectory,
        [string]$Distro
)

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $TempDirectory $distro
$rootfs = Join-Path $TempDirectory 'ubuntu-noble-wsl.rootfs.tar.gz'
Invoke-WebRequest `
    -Uri 'https://cloud-images.ubuntu.com/wsl/releases/noble/current/ubuntu-noble-wsl-amd64-wsl.rootfs.tar.gz' `
    -OutFile $rootfs
wsl --import $distro $installDir $rootfs --version 2
if ($LASTEXITCODE -ne 0) { throw 'WSL import failed' }

$wslWorkspace = & wsl -d $distro -u root --exec wslpath -a "$Source"
if ($LASTEXITCODE -ne 0 -or -not $wslWorkspace) {
    throw "Could not convert '$Source' to a WSL path."
}
$wslWorkspace = ([string] $wslWorkspace).Trim()

function ConvertTo-LfBase64 {
    param([string] $Text)
    $normalizedText = $Text -replace '\r\n?', "`n"
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($normalizedText))
}

# Normalize the checked-in Bash source before crossing the Windows/WSL boundary.
$prepareScript = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'prepare-wsl.sh')
$prepareEncoded = ConvertTo-LfBase64 $prepareScript
$workspaceEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($wslWorkspace))
$prepareCommand = "printf '%s' '$prepareEncoded' | base64 -d | bash -s -- '$workspaceEncoded'"
& wsl -d $distro -u root -- bash -lc "$prepareCommand" 2>&1 |
    Tee-Object -FilePath "$TempDirectory\wsl-$Mode.log"
if ($LASTEXITCODE -ne 0) { throw 'WSL preparation failed' }

# Keep Bash literal. Pass the two mode values as positional arguments.
$linuxScript = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'run-wsl.sh')
$encoded = ConvertTo-LfBase64 $linuxScript
& wsl -d $distro -u developer -- env HOME=/home/developer bash -lc `
    "printf '%s' '$encoded' | base64 -d | bash -s -- $Lite $Mode" 2>&1 |
    Tee-Object -FilePath "$TempDirectory\wsl-$Mode.log" -Append
$result = $LASTEXITCODE
if ($result -ne 0) { throw "WSL case failed with exit code $result" }
