<#
.SYNOPSIS
Apply and verify Windows dotfiles directly on the ephemeral GitHub Actions runner.
The runner is disposable, so no temporary user or Task Scheduler launcher is needed.
#>
param(
    [string]$Mode,
    [string]$Lite,
    [string]$Gui,
    [string]$Source,
    [string]$Log
)

$ErrorActionPreference = 'Stop'

function Update-InstallEnvironment {
    # Child installers cannot update this process. Reload Scoop's persisted uv
    # locations so verification and the next apply use the installed tools.
    foreach ($name in @('UV_CACHE_DIR', 'UV_PYTHON_BIN_DIR', 'UV_PYTHON_INSTALL_DIR', 'UV_TOOL_BIN_DIR', 'UV_TOOL_DIR')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($null -ne $value) {
            [Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }

    # Retain process-only paths such as the Chezmoi bootstrap directory.
    $paths = @(
        [Environment]::GetEnvironmentVariable('Path', 'User')
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $env:PATH
    )
    $env:PATH = (($paths -join ';') -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

Start-Transcript -Path $Log -Force
try {
    if ($env:GITHUB_ACTIONS -ne 'true') {
        throw 'run-windows.ps1 is intended for GitHub Actions only.'
    }

    # GitHub's Windows runner is elevated. Normal installs still reject elevated
    # shells; the bootstrap accepts this override only inside GitHub Actions.
    $env:DOTFILES_CI_ALLOW_ADMIN = '1'

    # Use a fresh Scoop root so preinstalled runner software cannot satisfy the
    # package checks accidentally. Scoop's CI bootstrap needs RunAsAdmin because
    # the hosted runner itself is elevated.
    $env:SCOOP = Join-Path $env:RUNNER_TEMP 'dotfiles-scoop'
    $scoopShim = Join-Path $env:SCOOP 'shims\scoop.ps1'
    if (-not (Test-Path -LiteralPath $scoopShim -PathType Leaf)) {
        $scoopInstaller = Join-Path $env:RUNNER_TEMP 'install-scoop.ps1'
        Invoke-WebRequest 'https://get.scoop.sh' -OutFile $scoopInstaller
        & $scoopInstaller -RunAsAdmin
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $scoopShim -PathType Leaf)) {
            throw 'Scoop CI bootstrap failed.'
        }
    }
    $env:PATH = (Join-Path $env:SCOOP 'shims') + ';' + $env:PATH

    $bin = Join-Path $env:RUNNER_TEMP 'chezmoi-bin'
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    iex "& { $(irm https://get.chezmoi.io/ps1) } -b '$bin'"
    $chezmoi = Join-Path $bin 'chezmoi.exe'

    & $chezmoi init -S $Source `
        --promptString 'Enter GitHub mail for this machine=testmail@example.com' `
        --promptBool "Do you want a minimal (lite) setup (y/n)=$Lite" `
        --promptBool "Install GUI tools (y/n)=$Gui" --apply
    if ($LASTEXITCODE -ne 0) { throw 'First Chezmoi apply failed' }

    Update-InstallEnvironment
    & pwsh -NoLogo -NoProfile -File (Join-Path $Source 'tests\verify-windows.ps1') -Mode $Mode
    if ($LASTEXITCODE -ne 0) { throw 'First verification failed' }

    # Rerun run_once scripts without resetting configuration or installed files.
    & $chezmoi -S $Source state delete-bucket --bucket=scriptState
    if ($LASTEXITCODE -ne 0) { throw 'Run-once state reset failed' }
    & $chezmoi -S $Source apply
    if ($LASTEXITCODE -ne 0) { throw 'Second Chezmoi apply failed' }

    Update-InstallEnvironment
    & pwsh -NoLogo -NoProfile -File (Join-Path $Source 'tests\verify-windows.ps1') -Mode $Mode
    if ($LASTEXITCODE -ne 0) { throw 'Second verification failed' }

    # run_after scripts remain pending, so verify only deployed files.
    & $chezmoi -S $Source verify --exclude=scripts
    if ($LASTEXITCODE -ne 0) { throw 'Chezmoi verify failed' }
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}
