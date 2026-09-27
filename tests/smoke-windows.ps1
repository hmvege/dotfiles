$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scratch = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-smoke-{0}" -f [guid]::NewGuid())
New-Item -ItemType Directory -Path $scratch | Out-Null

try {
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        throw 'chezmoi is required for template smoke tests'
    }

    $cases = @(
        @{ Name = 'lite'; Lite = 'true'; Gui = 'false' }
        @{ Name = 'full-cli'; Lite = 'false'; Gui = 'false' }
        @{ Name = 'full-gui'; Lite = 'false'; Gui = 'true' }
    )

    $templates = Get-ChildItem (Join-Path $repoRoot 'home\.chezmoiscripts') -Filter '*.ps1.tmpl'
    $templates += Get-Item (Join-Path $repoRoot 'home\private_Documents\private_PowerShell\Microsoft.PowerShell_profile.ps1.tmpl')

    foreach ($case in $cases) {
        $config = Join-Path $scratch ("config-{0}.toml" -f $case.Name)
        @"
[data]
email = "testmail@example.com"
lite = $($case.Lite)
gui = $($case.Gui)
"@ | Set-Content -LiteralPath $config

        foreach ($template in $templates) {
            $rendered = Join-Path $scratch ("{0}-{1}.ps1" -f $case.Name, $template.BaseName)
            Get-Content -Raw -LiteralPath $template.FullName |
                chezmoi -S (Join-Path $repoRoot 'home') -c $config execute-template |
                Set-Content -LiteralPath $rendered
            if ($LASTEXITCODE -ne 0) {
                throw "Chezmoi could not render $($template.FullName)"
            }

            $tokens = $null
            $errors = $null
            [Management.Automation.Language.Parser]::ParseFile(
                $rendered,
                [ref]$tokens,
                [ref]$errors
            ) | Out-Null
            if ($errors.Count -gt 0) {
                $errors | ForEach-Object { Write-Error $_ }
                throw "PowerShell syntax check failed for $rendered"
            }
        }
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output 'Windows template smoke checks passed.'
