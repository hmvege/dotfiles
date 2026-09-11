$ErrorActionPreference = 'Stop'

# Scoop and PowerShell modules belong to the original, non-elevated user.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
try {
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run chezmoi from a non-administrator terminal. Only the PowerShell MSI helper will request elevation.'
    }
}
finally {
    $identity.Dispose()
}

function Update-SetupPath {
    # Preserve process-only paths (including the Chezmoi bootstrap directory).
    $paths = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:PATH
    )
    $env:PATH = (($paths -join ';') -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Find-SetupPowerShell {
    $programFiles = $env:ProgramW6432
    if (-not $programFiles) { $programFiles = $env:ProgramFiles }
    $candidates = @(
        Get-Command pwsh.exe -CommandType Application -All -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Source
        Join-Path $programFiles 'PowerShell\7\pwsh.exe'
    )
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $output = @(& $candidate -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()')
        if ($LASTEXITCODE -ne 0 -or $output.Count -ne 1) {
            throw "Could not determine the PowerShell version at '$candidate'."
        }
        $versionText = ([string]$output[0]).Trim()
        if ($versionText -match '^\d+\.\d+\.\d+$' -and [Version]$versionText -ge [Version]'7.5.0') {
            return $candidate
        }
    }
    return $null
}

Update-SetupPath
$currentVersionText = $PSVersionTable.PSVersion.ToString()
if ($currentVersionText -notmatch '^\d+\.\d+\.\d+$' -or [Version]$currentVersionText -lt [Version]'7.5.0') {
    $setupPwsh = Find-SetupPowerShell
    if (-not $setupPwsh) {
        # sourceDir already includes the home/ selected by .chezmoiroot.
        $helper = Join-Path '{{ .chezmoi.sourceDir | replace "'" "''" }}' 'scripts\install_powershell.ps1'
        if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
            throw "PowerShell installation helper not found: $helper"
        }
        # Encode the command to preserve spaces and apostrophes through UAC.
        $helperLiteral = $helper.Replace("'", "''")
        $command = "try { & '$helperLiteral'; exit 0 } catch { Write-Error -ErrorAction Continue `$_; exit 1 }"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $process = Start-Process -FilePath $windowsPowerShell -Verb RunAs -Wait -PassThru `
            -ArgumentList "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded"
        if ($process.ExitCode -ne 0) {
            throw "PowerShell installation helper failed with exit code $($process.ExitCode)."
        }
        Update-SetupPath
        $setupPwsh = Find-SetupPowerShell
        if (-not $setupPwsh) {
            throw 'PowerShell 7.5 or newer is not available after installation. Restart Windows if requested, then rerun chezmoi apply.'
        }
    }
    $env:PATH = (Split-Path -Parent $setupPwsh) + ';' + $env:PATH
    # Rerun this rendered script as the original user, without loading the profile.
    & $setupPwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

# Use the selected running copy for subsequent child processes too.
$env:PATH = $PSHOME + ';' + $env:PATH
