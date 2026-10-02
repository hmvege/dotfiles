<#
.SYNOPSIS
Apply and verify Windows dotfiles twice inside the temporary standard-user profile.
#>
param([string]$Mode, [string]$Lite, [string]$Gui, [string]$Source, [string]$Log)
$ErrorActionPreference = 'Stop'
Start-Transcript -Path $Log -Force
try {
    # Own the source copy so Chezmoi can initialize Git metadata.
    $checkout = Join-Path $HOME 'dotfiles'
    New-Item -ItemType Directory -Path $checkout | Out-Null
    Copy-Item (Join-Path $Source '.chezmoiroot') $checkout
    Copy-Item (Join-Path $Source 'home') $checkout -Recurse
    Copy-Item (Join-Path $Source 'tests') $checkout -Recurse
    $Source = $checkout
    $bin = Join-Path $HOME 'bin'
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    iex "& { $(irm https://get.chezmoi.io/ps1) } -b '$bin'"
    $chezmoi = Join-Path $bin 'chezmoi.exe'
    & $chezmoi init -S $Source `
        --promptString 'Enter GitHub mail for this machine=testmail@example.com' `
        --promptBool "Do you want a minimal (lite) setup (y/n)=$Lite" `
        --promptBool "Install GUI tools (y/n)=$Gui" --apply
    if ($LASTEXITCODE -ne 0) { throw 'First Chezmoi apply failed' }
    & pwsh -NoLogo -NoProfile -File (Join-Path $Source 'tests\verify-windows.ps1') -Mode $Mode
    if ($LASTEXITCODE -ne 0) { throw 'First verification failed' }
    # Rerun run_once scripts without resetting configuration or installed files.
    & $chezmoi -S $Source state delete-bucket --bucket=scriptState
    if ($LASTEXITCODE -ne 0) { throw 'Run-once state reset failed' }
    & $chezmoi -S $Source apply
    if ($LASTEXITCODE -ne 0) { throw 'Second Chezmoi apply failed' }
    & pwsh -NoLogo -NoProfile -File (Join-Path $Source 'tests\verify-windows.ps1') -Mode $Mode
    if ($LASTEXITCODE -ne 0) { throw 'Second verification failed' }
    # run_after scripts remain pending, so verify only deployed files.
    & $chezmoi -S $Source verify --exclude=scripts
    if ($LASTEXITCODE -ne 0) { throw 'Chezmoi verify failed' }
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}
