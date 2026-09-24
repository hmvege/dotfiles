param(
    [Parameter(Mandatory)]
    [ValidateSet('lite', 'full-cli', 'full-gui')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

function Assert-Path {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected deployed file: $Path"
    }
}

function Assert-Command {
    param([string]$Name)
    $command = Get-Command $Name -CommandType Application,ExternalScript -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $command) { throw "Expected command: $Name" }
    return $command
}

function Assert-Module {
    param([string]$Name)
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "Expected PowerShell module: $Name"
    }
}

if (-not $IsWindows) { throw 'verify-windows.ps1 must run on Windows' }
# Installers run in child processes. Refresh their persisted user PATH before
# checking commands, just as a newly opened terminal would.
$env:PATH = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $env:PATH

$profilePath = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
Assert-Path (Join-Path $HOME '.gitconfig')
Assert-Path $profilePath
if ($Mode -eq 'lite') { Assert-Path (Join-Path $HOME '.vimrc') }
$scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
# These checks assume a fresh disposable test user, not a personal workstation.
$excluded = @()
if ($Mode -eq 'lite') { $excluded += @('lsd', 'oh-my-posh', 'cppcheck', 'coreutils') }
if ($Mode -ne 'full-gui') {
    $excluded += @('vscode', 'sublime-merge', 'windirstat', 'Meslo-NF', 'JetBrainsMono-NF')
}
foreach ($package in $excluded) {
    if (Test-Path (Join-Path $scoopRoot "apps\$package\current\install.json")) {
        throw "Excluded package was installed: $package"
    }
}

$commands = @('git', 'vim', 'fzf', 'ag', 'uv', 'zoxide', 'pwsh', 'bat')
if ($Mode -ne 'lite') {
    $commands += @(
        'cloc', 'cppcheck', 'fd', 'jq', 'lsd', 'rg', 'ls.exe', 'cat.exe',
        'black', 'flake8', 'mkdocs', 'mypy', 'pip-compile', 'pre-commit', 'ruff'
    )
}
foreach ($name in $commands) { Assert-Command $name | Out-Null }

Assert-Module 'PSFzf'
if ($Mode -eq 'lite') {
    $inventory = @(& uv tool list)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect uv tool inventory' }
    if ($inventory.Count -gt 0) { throw 'Lite provisioned uv tools' }
    $pythonRoot = (& uv python dir).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $pythonRoot) { throw 'Cannot locate managed Python directory' }
    if (Test-Path -LiteralPath $pythonRoot) {
        if (Get-ChildItem -LiteralPath $pythonRoot -Recurse -File -Filter 'python*.exe') {
            throw 'Lite downloaded managed Python'
        }
    }
}
if ($Mode -ne 'lite') {
    Assert-Module 'git-aliases'
    Assert-Module 'posh-git'

    $uvBin = (& uv tool dir --bin).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $uvBin) { throw 'uv tool bin directory is unavailable' }
    $uvBin = $uvBin.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $inventory = @(& uv tool list --show-python)
    if ($LASTEXITCODE -ne 0 -or -not ($inventory -match 'python')) {
        throw 'uv tool interpreters were not reported'
    }
    foreach ($name in @('ruff', 'black', 'flake8', 'mkdocs', 'mypy', 'pip-compile', 'pre-commit')) {
        $source = (Assert-Command $name).Source
        if (-not $source.StartsWith($uvBin, [StringComparison]::OrdinalIgnoreCase)) {
            throw "$name is not owned by uv: $source"
        }
    }
    $toolRoot = (& uv tool dir).Trim()
    $pythonRoot = (& uv python dir).Trim() + [IO.Path]::DirectorySeparatorChar
    foreach ($package in @('ruff', 'black', 'flake8', 'mkdocs', 'mypy', 'pip-tools', 'pre-commit')) {
        $python = Join-Path $toolRoot "$package\Scripts\python.exe"
        $basePrefix = & $python -c 'import sys; print(sys.base_prefix)'
        if ($LASTEXITCODE -ne 0 -or
            -not $basePrefix.StartsWith($pythonRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "$package does not use a uv-managed interpreter"
        }
    }
}

$profileCheck = @'
$ErrorActionPreference = 'Stop'
. $PROFILE
foreach ($pair in @(@('gco','Git-Checkout'), @('gc','Git-Commit'),
    @('gcmsg','Git-CommitMessage'), @('gcam','Git-CommitAllMessage'))) {
    if ((Get-Alias $pair[0]).Definition -ne $pair[1]) { exit 1 }
}
if ((Get-Alias ls).Definition -ne 'Get-ChildItem') { exit 1 }
'@
& pwsh -NoLogo -NoProfile -NonInteractive -Command $profileCheck
if ($LASTEXITCODE -ne 0) { throw 'PowerShell profile behavior check failed' }

if ($Mode -eq 'full-gui') {
    Assert-Command 'code' | Out-Null
    Assert-Command 'smerge' | Out-Null
    Assert-Command 'windirstat' | Out-Null
    $extensions = @(code --list-extensions)
    foreach ($extension in @('charliermarsh.ruff', 'ms-python.mypy-type-checker')) {
        if ($extension -notin $extensions) { throw "Missing VSCode extension: $extension" }
    }

    $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
    foreach ($font in @('Meslo-NF', 'JetBrainsMono-NF')) {
        $metadata = Join-Path $scoopRoot "apps\$font\current\install.json"
        if (-not (Test-Path -LiteralPath $metadata -PathType Leaf)) {
            throw "Missing Scoop font installation: $font"
        }
        $fontFiles = Get-ChildItem (Split-Path $metadata) -Recurse -File -Include '*.ttf', '*.otf'
        if (-not $fontFiles) { throw "Font package contains no font files: $font" }
    }
}

Write-Output "Verified Windows $Mode dotfiles for $env:USERNAME."
