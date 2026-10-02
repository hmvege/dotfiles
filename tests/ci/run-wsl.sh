#!/usr/bin/env bash
# Bootstrap Chezmoi and verify two WSL installation passes as the developer user.
# Run only in the disposable test environment prepared by the workflow.
# Arguments: lite flag and mode. Invoked as the developer user through WSL.

set -euo pipefail
lite="$1"
mode="$2"
mkdir -p "$HOME/.local/bin"
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
log=/tmp/install.log
root_shell_before="$(getent passwd root | cut -d: -f7)"
chezmoi init -S /dotfiles \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup (y/n)=$lite" \
    --promptBool "Install GUI tools (y/n)=false" \
    --apply 2>&1 | tee "$log"
bash /dotfiles/tests/verify-unix.sh "$mode"
test "$(getent passwd root | cut -d: -f7)" = "$root_shell_before"
# Rerun run_once scripts without resetting configuration or installed files.
chezmoi -S /dotfiles state delete-bucket --bucket=scriptState
chezmoi -S /dotfiles apply 2>&1 | tee -a "$log"
bash /dotfiles/tests/verify-unix.sh "$mode"
test "$(getent passwd root | cut -d: -f7)" = "$root_shell_before"
# run_after scripts remain pending, so verify only deployed files.
chezmoi -S /dotfiles verify --exclude=scripts
