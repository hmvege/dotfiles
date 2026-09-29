# Dotfiles testing

Use smoke checks for source safety, automated installation for non-GUI paths, Windows Sandbox for quick local Windows testing, and manual desktop checks for GUI behavior.

Manual installation acceptance starts in a fresh VM, snapshot, or Sandbox with no cloned repository or previous dotfiles installation. Use the platform's README bootstrap command and let Chezmoi download the repository. Branch tests require a published branch. Source-only checks and Docker investigation are separate developer checks.

## Test matrix

| Layer                               | Trigger                  | Platform and mode                               | Purpose                                                                                                         |
| ----------------------------------- | ------------------------ | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Smoke                               | Pull request             | Ubuntu, macOS, Windows, all modes               | Whitespace, workflow YAML, template rendering, and shell syntax. No packages are installed.                     |
| Installation                        | Push to `master`         | Ubuntu 22.04, 24.04, 26.04 lite and full CLI    | Docker apply, same-home repeat apply, and verification.                                                         |
| Installation                        | Push to `master`         | Rocky 8 lite and full CLI                       | Docker apply, same-home repeat apply, and verification.                                                         |
| Resilience                          | Push to `master`         | Ubuntu 24.04 lite                               | Root without sudo, unprivileged without passwordless sudo, optional package failure, and uv ownership conflict. |
| Installation                        | Push to `master`         | macOS and WSL2                                  | Existing lite and full CLI or GUI matrix.                                                                       |
| Installation                        | Manual workflow dispatch | Windows lite, full CLI, and full GUI            | Temporary standard-user installation and verification.                                                          |
| Installation and desktop acceptance | Manual Windows Sandbox   | Windows lite, full CLI, and full GUI            | Local installation, repeat apply, profile checks, and GUI inspection.                                           |
| Desktop acceptance                  | Manual                   | Ubuntu Desktop 22.04, 24.04, and 26.04 full GUI | Visual terminal, editor, Gogh, fonts, and repeat-apply behavior.                                                |

Ubuntu GUI is intentionally not an automated Docker installation case. Snap needs `snapd`, which a plain Docker image does not provide, so it cannot install VSCode or provide `code`. GUI template rendering still runs in smoke checks.

## Automated checks

Every installation case applies once, runs the platform verifier, clears only Chezmoi's `scriptState` bucket, applies again in the same home, reruns the verifier, and finishes with `chezmoi verify --exclude=scripts`. Failed cases upload their logs.

Full Unix setups install Vim plugins without a terminal and load Everforest to check the result. Installation or theme loading failures stop setup and print Vim diagnostics.

Run source-only developer checks from a local checkout:

```sh
bash tests/smoke-unix.sh
git diff --check
```

macOS and WSL2 installation tests run on `master`. Windows installation is opt-in because it uses a Windows hosted runner and may install a substantial tool set.

## Test Windows locally with Windows Sandbox

See document on [Windows Sandbox testing](windows-sandbox-testing.md)


## Run Windows installation through GitHub Actions

The workflow creates a temporary standard user and one limited scheduled task to obtain that user's real profile. It runs all three Windows modes, has a 45-minute limit per mode, and removes the task and user afterward.

In GitHub, open **Actions** → **Test Dotfiles Installation** → **Run workflow**, then select the branch. With the GitHub CLI from the checkout:

```sh
branch="$(git branch --show-current)"
gh workflow run test-dotfiles.yml --ref "$branch"
gh run watch
```

## Manual Ubuntu desktop GUI acceptance

Start with a fresh Ubuntu Desktop 22.04, 24.04, or 26.04 VM or snapshot and a normal sudo-capable user. Do not clone the repository first. Install the README prerequisites:

```bash
sudo apt-get update
sudo apt-get install -y curl
```

Run the Linux README bootstrap command:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --apply hmvege
```

To test a published branch, use this instead:

```bash
branch='your-published-branch'
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --branch "$branch" --apply hmvege
```

Use a test email. For desktop GUI acceptance, answer no to lite and yes to GUI. Stop at any installation error and save the terminal output.

Verify the downloaded configuration, then force the installers to run again in the same home:

```bash
bash "$HOME/dotfiles/tests/verify-unix.sh" full-gui

"$HOME/.local/bin/chezmoi" -S "$HOME/dotfiles" state delete-bucket --bucket=scriptState
"$HOME/.local/bin/chezmoi" -S "$HOME/dotfiles" apply
bash "$HOME/dotfiles/tests/verify-unix.sh" full-gui
"$HOME/.local/bin/chezmoi" -S "$HOME/dotfiles" verify -x scripts
```

Log out and log in, then open a new terminal. Confirm it starts Zsh automatically without running Zsh manually. Check terminal-profile command overrides if it does not. Confirm shell startup, fzf history, zoxide, lsd aliases, Vim, Gogh in GNOME Terminal, VSCode and Sublime configuration, Ruff and mypy discovery, Nerd Font glyphs, and Sublime Merge. Run Codex interactively to check first-launch sign-in. Record the date, downloaded commit SHA, release, mode, result, and any failure. Rocky keeps its existing login shell.

## Local Docker investigation

This developer check uses a local checkout copied into the image at build time. It helps investigate non-GUI Linux installation issues but does not test the README bootstrap or desktop acceptance. Build and enter the container on the host:

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
```

After exiting, save logs if needed and remove the named container:

```sh
docker logs dotfiles-manual-test > dotfiles-manual-test.log 2>&1
docker rm dotfiles-manual-test
```

Rebuild the image and create a new container after changing `home/` or `.chezmoiroot`. An existing container retains its old source files even after the image is rebuilt.
