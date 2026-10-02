#!/usr/bin/env bash
# Apply and verify a macOS installation twice, preserving the root shell.
# Run only in the disposable test environment prepared by the workflow.
# Arguments: mode, lite flag, GUI flag, source directory, installation log.

set -eo pipefail

MODE="$1"
LITE="$2"
GUI="$3"
source_dir="$4"
export DOTFILES_INSTALL_LOG="$5"

# Capture verifier and state-reset errors as well as installation output.
exec > >(tee "$DOTFILES_INSTALL_LOG") 2>&1
root_shell_before="$(dscl . -read /Users/root UserShell)"
chezmoi init -S "$source_dir" \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup (y/n)=$LITE" \
    --promptBool "Install GUI tools (y/n)=$GUI" \
    --apply
bash "$source_dir/tests/verify-unix.sh" "$MODE"
test "$(dscl . -read /Users/root UserShell)" = "$root_shell_before"
# Rerun run_once scripts without resetting configuration or installed files.
chezmoi -S "$source_dir" state delete-bucket --bucket=scriptState
chezmoi -S "$source_dir" apply
bash "$source_dir/tests/verify-unix.sh" "$MODE"
test "$(dscl . -read /Users/root UserShell)" = "$root_shell_before"
# run_after scripts remain pending, so verify only deployed files.
chezmoi -S "$source_dir" verify --exclude=scripts
