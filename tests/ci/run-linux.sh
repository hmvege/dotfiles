#!/usr/bin/env bash
# Apply and verify a Linux installation twice, preserving the root shell.
# Run only in the disposable test environment prepared by the workflow.
# Arguments: mode, lite flag, GUI flag. Uses DOTFILES_INSTALL_LOG for apply output.

set -euo pipefail

MODE="$1"
LITE="$2"
GUI="$3"

# Chezmoi creates Git metadata. Give each disposable user a writable copy.
cp -R /dotfiles "$HOME/dotfiles"
root_shell_before="$(getent passwd root | cut -d: -f7)"
chezmoi init -S "$HOME/dotfiles" \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup (y/n)=$LITE" \
    --promptBool "Install GUI tools (y/n)=$GUI" \
    --apply 2>&1 | tee "$DOTFILES_INSTALL_LOG"
bash /tests/verify-unix.sh "$MODE"
test "$(getent passwd root | cut -d: -f7)" = "$root_shell_before"
# Rerun run_once scripts without resetting config or installed files.
chezmoi -S "$HOME/dotfiles" state delete-bucket --bucket=scriptState
chezmoi -S "$HOME/dotfiles" apply 2>&1 | tee -a "$DOTFILES_INSTALL_LOG"
bash /tests/verify-unix.sh "$MODE"
test "$(getent passwd root | cut -d: -f7)" = "$root_shell_before"
# run_after scripts always appear pending. Verify deployed files.
chezmoi -S "$HOME/dotfiles" verify --exclude=scripts
