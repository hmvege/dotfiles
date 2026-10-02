#!/usr/bin/env bash
# Prepare the disposable Ubuntu WSL distribution and its developer account.
# Run only in the disposable test environment prepared by the workflow.
# Argument: base64-encoded checkout path, preserving spaces across the WSL boundary.

set -euo pipefail
workspace="$(printf '%s' "$1" | base64 -d)"
# Keep the source writable for Chezmoi under the developer account.
mkdir -p /dotfiles
cp -a "$workspace/." /dotfiles/
apt-get update
apt-get install -y ca-certificates curl git sudo
useradd --create-home --shell /bin/bash developer
echo 'developer ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/developer
chmod 0440 /etc/sudoers.d/developer
chown -R developer:developer /home/developer /dotfiles
