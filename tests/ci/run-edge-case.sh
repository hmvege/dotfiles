#!/usr/bin/env bash
# Exercise one Linux lite resilience scenario and verify both applies.
# Run only in the disposable test environment prepared by the workflow.
# Argument: root-no-sudo, unprivileged-no-sudo, or optional-package-failure.

set -euo pipefail

EDGE_CASE="$1"

verification_args=()
if [ "$EDGE_CASE" = root-no-sudo ]; then
    mv /usr/bin/sudo /usr/bin/sudo.disabled
    ! command -v sudo
elif [ "$EDGE_CASE" = optional-package-failure ]; then
    mkdir -p /tmp/mockbin
    printf "#!/bin/sh\necho mocked apt-get failure >&2\nexit 1\n" > /tmp/mockbin/apt-get
    chmod +x /tmp/mockbin/apt-get
    export PATH="/tmp/mockbin:$PATH"
else
    # Confirm this is really the no-passwordless-sudo case.
    if sudo -n true 2>/dev/null; then
        echo "Unexpected sudo access" >&2
        exit 1
    fi
fi
# These two cases test configuration despite missing optional tools.
# The normal lite matrix and root case still require every tool.
if [ "$EDGE_CASE" != root-no-sudo ]; then
    verification_args=(--configuration-only)
fi
log=/tmp/install.log
cp -R /dotfiles "$HOME/dotfiles"
chezmoi init -S "$HOME/dotfiles" \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup (y/n)=true" \
    --promptBool "Install GUI tools (y/n)=false" \
    --apply 2>&1 | tee "$log"
if [ "$EDGE_CASE" = optional-package-failure ]; then
    grep -Fq "mocked apt-get failure" "$log"
    grep -Fq "Continuing lite setup" "$log"
fi
bash /tests/verify-unix.sh lite "${verification_args[@]}"
# Rerun run_once scripts without resetting configuration or installed files.
chezmoi -S "$HOME/dotfiles" state delete-bucket --bucket=scriptState
chezmoi -S "$HOME/dotfiles" apply 2>&1 | tee -a "$log"
bash /tests/verify-unix.sh lite "${verification_args[@]}"
# run_after scripts remain pending, so verify only deployed files.
chezmoi -S "$HOME/dotfiles" verify --exclude=scripts
