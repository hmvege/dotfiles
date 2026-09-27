# Repository Guidelines

## Project Structure & Module Organization

This repository manages cross-platform dotfiles with Chezmoi; `.chezmoiroot` selects `home/` as the source directory.

- `home/`: shell, Git, Vim, terminal, and editor configuration, including `.tmpl` Go templates.
- `home/.chezmoiscripts/`: platform-specific installation and post-install scripts.
- `home/.chezmoitemplates/`: shared installation helpers and shell fragments.
- `home/.chezmoi.toml.tmpl`, `.chezmoiignore`, and `.chezmoiexternal.toml`: setup prompts, deployment exclusions, and external dependencies.
- `tests/`: Bash and PowerShell checks plus Ubuntu and Rocky Dockerfiles.
- `.github/workflows/test-dotfiles.yml`: CI matrix. `docs/dotfiles-testing.md` documents detailed validation and desktop checklists.

## Build, Test, and Development Commands

There is no application build. Run commands from the repository root:

- `chezmoi diff -S "$PWD"`: inspect pending configuration changes.
- `chezmoi apply -n -v -S "$PWD"`: preview deployment without applying it.
- `chezmoi apply -v -S "$PWD"`: deploy configuration and execute eligible installation scripts.
- `bash tests/smoke-unix.sh`: render all setup modes, check Bash/Zsh syntax, and test Python-tool conflicts; requires Chezmoi and Zsh.
- `pwsh -File tests/smoke-windows.ps1`: render and parse Windows templates; requires Chezmoi.
- `git diff --check`: detect whitespace errors.

## Coding Style & Naming Conventions

Follow surrounding formatting; shell and PowerShell test blocks use four-space indentation. Quote shell paths and use descriptive variable names. Preserve Chezmoi attributes such as `dot_`, `private_`, `.tmpl`, and ordered `run_once_after_` script names. Keep shared logic in `.chezmoitemplates/` and guard platform-specific behavior. Ruff settings configure deployed Python tooling; they are not a repository-wide lint gate.

## Testing Guidelines

Tests use standalone Bash and PowerShell scripts, without a numeric coverage target. Follow `smoke-<platform>`, `verify-<platform>`, and `test-<behavior>` naming. Exercise `lite`, `full-cli`, and `full-gui` where applicable. For installer changes, use disposable environments and verify repeated application in the same home using the documented procedure. GUI behavior requires manual desktop checks.

Tests should be added cautiously. That is, if the feature is not implicitly tested in github actions pipeline or via VM full gui tests, should a test be considered. Always ask if test is to be added with reason and purpose for adding the test.

## Commit & Pull Request Guidelines

Use the history's bracketed prefixes, such as `[ADD]`, `[REFACTOR]`, and `[DOCS]`, followed by a concise description. Keep changes focused. PR descriptions should identify affected platforms and modes, summarize behavior changes, report validation and remaining gaps, and link relevant issues. Include screenshots when changing visible desktop behavior.

## General rules
- Use built-in editor for updating scripts.
- Avoid using `;` and `--` when writing documentation.
- Prefer terseness and conciseness as opposed to verbosity.
- Follow the same style of documentation as currently exists in README.md. 