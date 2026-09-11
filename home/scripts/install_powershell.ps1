#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[Version] $MinVersion = '7.5.0'
# Stay on an MSI-producing release series; do not follow /releases/latest.
[Version] $MsiSeries = '7.6'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer supports Windows only.'
}

# Preserve the original Windows x64 target, including a 32-bit bootstrap host.
$architecture = $env:PROCESSOR_ARCHITEW6432
if (-not $architecture) { $architecture = $env:PROCESSOR_ARCHITECTURE }
if ($architecture -ne 'AMD64') {
    throw "This installer requires Windows x64; detected '$architecture'."
}

$programFiles = $env:ProgramW6432
if (-not $programFiles) { $programFiles = $env:ProgramFiles }
$installRoot = Join-Path $programFiles 'PowerShell'
$managedPwsh = Join-Path $installRoot '7\pwsh.exe'

function Get-StablePwshVersion {
    param([Parameter(Mandatory)][string] $Path)

    $output = @(& $Path -NoLogo -NoProfile -NonInteractive -Command '
        $PSVersionTable.PSVersion.ToString()
    ')
    if ($LASTEXITCODE -ne 0 -or $output.Count -ne 1) {
        throw "Could not determine the PowerShell version at '$Path'."
    }

    $versionText = ([string] $output[0]).Trim()
    if ($versionText -match '^\d+\.\d+\.\d+-') {
        return $null # Preview/RC builds do not satisfy the requirement.
    }

    [Version] $version = $null
    if ($versionText -notmatch '^\d+\.\d+\.\d+$' -or
        -not [Version]::TryParse($versionText, [ref] $version)) {
        throw "Unexpected PowerShell version '$versionText' from '$Path'."
    }
    return $version
}

function Get-MsiRelease {
    param([Parameter(Mandatory)][Version] $Series)

    $headers = @{
        Accept = 'application/vnd.github+json'
        'User-Agent' = 'chezmoi-dotfiles'
    }
    $bestRelease = $null
    [Version] $bestVersion = '0.0.0'
    $page = 1

    # Scan all pages and compare versions: release order need not be semver order.
    do {
        $uri = "https://api.github.com/repos/PowerShell/PowerShell/releases?per_page=100&page=$page"
        [object[]] $releases = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 60
        if (-not $releases) { break }

        foreach ($release in $releases) {
            if ($release.draft -or $release.prerelease -or
                $release.tag_name -notmatch '^v(\d+\.\d+\.\d+)$') {
                continue
            }

            [Version] $version = $Matches[1]
            if ($version.Major -eq $Series.Major -and
                $version.Minor -eq $Series.Minor -and
                $version -gt $bestVersion) {
                $bestRelease = $release
                $bestVersion = $version
            }
        }
        $page++
    } while ($releases.Count -eq 100)

    if ($null -eq $bestRelease) {
        throw "No stable PowerShell $Series release was found."
    }
    return $bestRelease
}

$pwshCmd = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($pwshCmd) {
    $current = Get-StablePwshVersion -Path $pwshCmd.Source
    if ($null -ne $current -and $current -ge $MinVersion) {
        Write-Host "PowerShell $current meets the minimum $MinVersion - skipping installation."
        return
    }
}

# Avoid repeatedly installing when PATH selects a different copy or is stale.
if (Test-Path -LiteralPath $managedPwsh -PathType Leaf) {
    $managedVersion = Get-StablePwshVersion -Path $managedPwsh
    if ($null -ne $managedVersion -and $managedVersion -ge $MinVersion) {
        Write-Host "PowerShell $managedVersion is already installed at '$managedPwsh'."
        Write-Warning 'PATH does not select a suitable stable copy. Restart your terminal and check PATH order.'
        return
    }
}

# Checking an existing installation needs no elevation; installing does.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
try {
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Installing PowerShell requires an elevated PowerShell session. Run as administrator and retry.'
    }
}
finally {
    $identity.Dispose()
}

$originalTls = [Net.ServicePointManager]::SecurityProtocol
$originalProgress = $ProgressPreference
$installerPath = $null

try {
    [Net.ServicePointManager]::SecurityProtocol = $originalTls -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'

    $release = Get-MsiRelease -Series $MsiSeries
    [Version] $latestVersion = $release.tag_name.Substring(1)
    if ($latestVersion -lt $MinVersion) {
        throw "Latest stable PowerShell $MsiSeries patch ($latestVersion) is below the minimum $MinVersion."
    }

    $installerName = "PowerShell-$latestVersion-win-x64.msi"
    $installerAssets = @($release.assets | Where-Object { $_.name -eq $installerName })
    $checksumAssets = @($release.assets | Where-Object { $_.name -eq 'hashes.sha256' })
    if ($installerAssets.Count -ne 1 -or $checksumAssets.Count -ne 1) {
        throw "PowerShell $latestVersion is missing the expected MSI or checksum asset."
    }

    $response = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 `
        -Uri $checksumAssets[0].browser_download_url

    $checksumText = $response.Content
    if ($checksumText -is [byte[]]) {
        $checksumText = [Text.Encoding]::UTF8.GetString($checksumText)
    }
    $checksumText = ([string] $checksumText).TrimStart([char] 0xFEFF)

    $pattern = '(?im)^([a-f0-9]{64})[ \t]+\*?' + [regex]::Escape($installerName) + '[ \t]*\r?$'
    $checksumMatches = [regex]::Matches($checksumText, $pattern)
    if ($checksumMatches.Count -ne 1) {
        throw "Could not find a unique SHA-256 checksum for $installerName."
    }
    $expectedHash = $checksumMatches[0].Groups[1].Value

    $baseName = 'PowerShell-' + [Guid]::NewGuid().ToString('N')
    $installerPath = Join-Path ([IO.Path]::GetTempPath()) "$baseName.msi"
    $logPath = Join-Path ([IO.Path]::GetTempPath()) "$baseName.log"

    Write-Host "Downloading PowerShell $latestVersion..."
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 600 `
        -Uri $installerAssets[0].browser_download_url -OutFile $installerPath

    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        throw "SHA-256 mismatch: expected $expectedHash, got $actualHash."
    }

    Write-Host "Checksum verified - installing. MSI log: $logPath"

    # Explicitly manage the standard MSI location; leave other installer options at their defaults.
    $arguments = "/i `"$installerPath`" /qn /norestart /L*v `"$logPath`" ADD_PATH=1 INSTALLFOLDER=`"$installRoot`""
    $installer = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" `
        -ArgumentList $arguments -Wait -PassThru

    if ($installer.ExitCode -notin @(0, 3010)) {
        throw "PowerShell MSI installation failed with exit code $($installer.ExitCode). Log: $logPath"
    }

    if ($installer.ExitCode -eq 3010) {
        Write-Warning "MSI completed successfully but requires a restart. Version verification is deferred. Log: $logPath"
        return
    }

    if (-not (Test-Path -LiteralPath $managedPwsh -PathType Leaf)) {
        throw "MSI reported success but '$managedPwsh' is missing. Log: $logPath"
    }

    $installedVersion = Get-StablePwshVersion -Path $managedPwsh
    if ($null -eq $installedVersion -or $installedVersion -lt $latestVersion) {
        throw "MSI reported success but the installed version is not stable $latestVersion or newer. Log: $logPath"
    }

    Write-Host "Verified PowerShell $installedVersion at '$managedPwsh'."
    Write-Host 'Restart your terminal to pick up the updated PATH.'

    if ($pwshCmd -and $pwshCmd.Source -ne $managedPwsh) {
        Write-Warning "Another pwsh.exe was selected before installation: '$($pwshCmd.Source)'. Check PATH order after restarting."
    }
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $originalTls
    $ProgressPreference = $originalProgress

    try {
        if ($installerPath -and (Test-Path -LiteralPath $installerPath)) {
            Remove-Item -LiteralPath $installerPath -Force
        }
    }
    catch {
        Write-Warning "Could not remove temporary installer '$installerPath': $_"
    }

    # Keep the MSI log for diagnosis, including after successful installation.
}