# Dotfiles testing

Use smoke checks for source safety, automated installation for non-GUI paths, and manual desktop checks for Ubuntu GUI behavior.

## Test matrix

| Layer | Trigger | Platform and mode | Purpose |
| --- | --- | --- | --- |
| Smoke | Pull request | Ubuntu, macOS, Windows, all modes | Whitespace, workflow YAML, template rendering, and shell syntax. No packages are installed. |
| Installation | Push to `master` | Ubuntu 22.04, 24.04, 26.04 lite and full CLI | Docker apply, same-home repeat apply, and verification. |
| Installation | Push to `master` | Rocky 8 lite and full CLI | Docker apply, same-home repeat apply, and verification. |
| Resilience | Push to `master` | Ubuntu 24.04 lite | Root without sudo, unprivileged without passwordless sudo, optional package failure, and uv ownership conflict. |
| Installation | Push to `master` | macOS and WSL2 | Existing lite and full CLI or GUI matrix. |
| Installation | Manual workflow dispatch | Windows lite, full CLI, and full GUI | Temporary standard-user installation and verification. |
| Desktop acceptance | Manual | Ubuntu Desktop 22.04, 24.04, and 26.04 full GUI | Visual terminal, editor, Gogh, fonts, and repeat-apply behavior. |

Ubuntu GUI is intentionally not an automated Docker installation case. Snap needs `snapd`, which a plain Docker image does not provide, so it cannot install VSCode or provide `code`. GUI template rendering still runs in smoke checks.

## Automated checks

Every installation case applies once, runs the platform verifier, clears only Chezmoi's `scriptState` bucket, applies again in the same home, reruns the verifier, and finishes with `chezmoi verify --exclude=scripts`. Failed cases upload their logs.

The full CLI Vim setup can currently block a repeat apply with `Press ENTER`. Treat that as an automated-installation failure. Do not bypass the prompt and call the case unattended success.

Run source-only checks locally:

```sh
bash tests/smoke-unix.sh
git diff --check
```

macOS and WSL2 installation tests run on `master`. Windows installation is opt-in because it uses a Windows hosted runner and may install a substantial tool set.

## Run Windows installation manually

The workflow creates a temporary standard user and one limited scheduled task to obtain that user's real profile. It runs all three Windows modes, has a 45-minute limit per mode, and removes the task and user afterward.

In GitHub, open **Actions** → **Test Dotfiles Installation** → **Run workflow**, then select the branch. With the GitHub CLI from the checkout:

```sh
branch="$(git branch --show-current)"
gh workflow run test-dotfiles.yml --ref "$branch"
gh run watch
```

## Manual Ubuntu desktop GUI acceptance

Run these commands from a checkout at the commit under test on a fresh Ubuntu Desktop 22.04, 24.04, or 26.04 VM or snapshot. Use a normal sudo-capable user.

```sh
set -euo pipefail
sudo apt-get update
sudo apt-get install -y curl git
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

chezmoi init -S "$PWD" \
  --promptString "Enter GitHub mail for this machine=testmail@example.com" \
  --promptBool "Do you want a minimal (lite) setup (y/n)=false" \
  --promptBool "Install GUI tools (y/n)=true" \
  --apply
bash tests/verify-unix.sh full-gui

chezmoi -S "$PWD" state delete-bucket --bucket=scriptState
chezmoi -S "$PWD" apply
bash tests/verify-unix.sh full-gui
chezmoi -S "$PWD" verify --exclude=scripts
```

Confirm Zsh startup, fzf history, zoxide, lsd aliases, Vim, Gogh in GNOME Terminal, VSCode and Sublime configuration, Ruff and mypy discovery, Nerd Font glyphs, and Sublime Merge. Record the date, commit SHA, release, mode, result, and any failure.

## Local Docker investigation

Docker is useful for non-GUI Linux installation issues. It is not desktop acceptance. Build and enter the container on the host:

```sh
ubuntu_version=24.04
docker build --build-arg "UBUNTU_VERSION=$ubuntu_version" \
  -f tests/LinuxUbuntu/Dockerfile -t "dotfiles-ubuntu:$ubuntu_version" .
docker run -it --name dotfiles-manual-test \
  -v "$PWD/tests:/tests:ro" "dotfiles-ubuntu:$ubuntu_version" bash
```

Inside the container, choose one mode, then run the apply sequence:

```sh
# Lite
mode=lite lite=true gui=false

# Or full CLI
# mode=full-cli lite=false gui=false

set -euo pipefail
cp -R /dotfiles "$HOME/dotfiles"
chezmoi init -S "$HOME/dotfiles" \
  --promptString "Enter GitHub mail for this machine=testmail@example.com" \
  --promptBool "Do you want a minimal (lite) setup (y/n)=$lite" \
  --promptBool "Install GUI tools (y/n)=$gui" \
  --apply
bash /tests/verify-unix.sh "$mode"

chezmoi -S "$HOME/dotfiles" state delete-bucket --bucket=scriptState
chezmoi -S "$HOME/dotfiles" apply
bash /tests/verify-unix.sh "$mode"
chezmoi -S "$HOME/dotfiles" verify --exclude=scripts
exit
```

After exiting, save logs if needed and remove the named container:

```sh
docker logs dotfiles-manual-test > dotfiles-manual-test.log 2>&1
docker rm dotfiles-manual-test
```

Rebuild the image after changing `home/` or `.chezmoiroot`.
