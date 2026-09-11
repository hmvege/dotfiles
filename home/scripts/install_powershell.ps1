Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[Version] $MinVersion = '7.5.0'

# .NET-based hashing also works in Windows PowerShell during bootstrap.
function Get-SHA256Hash {
    param([string]$Path)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hashBytes = $sha256.ComputeHash($stream)
            return ([BitConverter]::ToString($hashBytes)).Replace('-', '').ToUpperInvariant()
        }
        finally {
            $stream.Dispose()
        }
    }
    finally {
        $sha256.Dispose()
    }
}

function Install-PowerShell {
    # GitHub's latest endpoint selects a stable release, excluding previews.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' `
        -Headers @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'chezmoi-dotfiles' }

    if ($release.draft -or $release.prerelease -or $release.tag_name -notmatch '^v(\d+\.\d+\.\d+)$') {
        throw 'The latest PowerShell release is not a stable version.'
    }
    [Version] $latestVersion = $Matches[1]
    if ($latestVersion -lt $MinVersion) {
        throw "Latest PowerShell release $latestVersion is below the required minimum $MinVersion."
    }

    # Retain the existing Windows x64 MSI installation target.
    $installerName = "PowerShell-$latestVersion-win-x64.msi"
    $installerAssets = @($release.assets | Where-Object { $_.name -eq $installerName })
    $checksumAssets = @($release.assets | Where-Object { $_.name -eq 'hashes.sha256' })
    if ($installerAssets.Count -ne 1 -or $checksumAssets.Count -ne 1) {
        throw "PowerShell $latestVersion is missing the expected MSI or checksum asset."
    }

    # Resolve both assets from the same release so a newer release cannot mix versions.
    $checksumResponse = Invoke-WebRequest -UseBasicParsing -Uri $checksumAssets[0].browser_download_url
    $checksumText = $checksumResponse.Content
    if ($checksumText -is [byte[]]) {
        $checksumText = [Text.Encoding]::UTF8.GetString($checksumText)
    }
    $checksumPattern = '(?im)^([a-f0-9]{64})[ \t]+\*?' + [regex]::Escape($installerName) + '[ \t]*\r?$'
    $checksumMatches = [regex]::Matches([string]$checksumText, $checksumPattern)
    if ($checksumMatches.Count -ne 1) {
        throw "Could not find a unique SHA-256 checksum for $installerName."
    }
    $expectedHash = $checksumMatches[0].Groups[1].Value

    $installerPath = Join-Path ([IO.Path]::GetTempPath()) ("PowerShell-" + [Guid]::NewGuid().ToString('N') + '.msi')
    try {
        Write-Host "Downloading latest stable PowerShell $latestVersion..."
        Invoke-WebRequest -UseBasicParsing -Uri $installerAssets[0].browser_download_url -OutFile $installerPath

        Write-Host 'Verifying SHA-256 checksum...'
        $actualHash = Get-SHA256Hash $installerPath
        if ($actualHash -ne $expectedHash) {
            throw "HASH MISMATCH! Expected $expectedHash got $actualHash"
        }

        Write-Host 'Hash OK - installing...'
        $installer = Start-Process msiexec.exe -Wait -PassThru `
            -ArgumentList "/i `"$installerPath`" /qn /norestart"
        if ($installer.ExitCode -notin @(0, 3010)) {
            throw "PowerShell MSI installation failed with exit code $($installer.ExitCode)."
        }
        Write-Host "PowerShell $latestVersion installed."
        if ($installer.ExitCode -eq 3010) {
            Write-Host 'A restart is required to finish installation.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $installerPath) {
            Remove-Item -LiteralPath $installerPath -Force
        }
    }
}

$pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if (-not $pwshCmd) {
    Write-Host 'No PowerShell 7 detected - installing the latest stable release.'
    Install-PowerShell
    return
}

$currString = & $pwshCmd.Source -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()'
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the installed PowerShell version.'
}

# Preview builds do not satisfy the stable-version requirement.
[Version] $current = $null
if (-not [Version]::TryParse($currString.Trim(), [ref]$current)) {
    Write-Host "PowerShell version '$currString' is not a stable version - installing the latest stable release."
    Install-PowerShell
}
elseif ($current -lt $MinVersion) {
    Write-Host "PowerShell $current is older than $MinVersion - installing the latest stable release."
    Install-PowerShell
}
else {
    Write-Host "PowerShell $current meets the minimum $MinVersion - skipping installation."
}
