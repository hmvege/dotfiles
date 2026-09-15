![Badge](https://github.com/hmvege/dotfiles/actions/workflows/test-dotfiles.yml/badge.svg)

# Dotfiles

Dotfiles repository for `hmvege`, managed with [Chezmoi](https://github.com/twpayne/chezmoi).

Feel free to use on your own risk, or to draw inspiration.

## :dart: Goals
The goal for this dotfiles project repository, is following,
* Have a, as close to as possible, fully **automatized dotfiles setup**.
* Have the setup **install packages automatically**.
* Have a **cross-platform** dotfiles setup, working for
   * MacOS
   * Ubuntu 20.04
   * Ubuntu 22.04
   * Ubuntu 24.04
   * Rocky8
   * WSL 2
   * Windows 11
* Have it be easily **maintained**. I.e. changes applied at one machine, will be easily transferable to another machine.

## :scroll: Installation

### :question: Prompted Questions
During the installation, you'll be asked:
- **Mail** used for GitHub.
- Whether to perform a **minimal (lite) setup**. Lite mode forces GUI installation off, but currently still includes development tools such as tmux on Ubuntu.
- Whether to **install GUI apps** (e.g., VSCode, Sublime, fonts). There is no automatic GUI recommendation. Lite mode overrides GUI choice and no GUI apps are installed.

### :penguin: Linux
Install Chezmoi and initialize, ensure `curl` and `sudo` is installed,
```bash
apt-get update && apt-get install -y curl sudo
```
then download and apply the dotfiles,
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --apply hmvege
```
which will download the Chezmoi binary to `$HOME/.local/bin`, and use `~/dotfiles` as source for Chezmoi by downloading this repository to this location.

### :green_apple:	MacOS
On MacOS, you should be able to install Chezmoi via
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --apply hmvege
```

### :window: Windows
The Windows setup targets x64 Windows and PowerShell 7. Start in a **non-administrator** terminal (Windows PowerShell 5.1 can bootstrap it), then install Chezmoi:
```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '~/bin' -- init -S ~/dotfiles --apply hmvege"
```
The PowerShell installer accepts an existing stable version 7.5.0 or newer. When installation is needed, it selects the newest stable patch in the **7.6 MSI series** from the [official PowerShell releases](https://github.com/PowerShell/PowerShell/releases), verifies the published SHA-256 checksum, and retains an MSI log in the temporary directory.

If a restart is needed before PowerShell becomes usable, restart Windows and rerun `chezmoi apply -v -S ~/dotfiles`.

After setup, open **PowerShell** in Windows Terminal, or run `pwsh` from a new terminal. `powershell.exe` launches Windows PowerShell 5.1, and `pwsh.exe` launches PowerShell 7. The managed profile is `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`. In PowerShell 7, `$PROFILE` shows the actual profile location. Machines with redirected Documents folders should check that it matches the deployed path. Choose PowerShell as Windows Terminal's default profile if desired.

### Pulling latest changing from repository
Pull latest changes from repository.
```bash
chezmoi update -v -S ~/dotfiles
```

### Apply changes
Apply the changes made to the dotfiles made through `chezmoi edit [$FILE]`
```bash
chezmoi apply -v -S ~/dotfiles
```
`-v` displays what changes is being made. If `-n`, a dry run will be performed.

### Add changes to Chezmoi dotfiles
Apply the changes made to the dotfiles made through `chezmoi edit [$FILE]`
```bash
chezmoi add -S ~/dotfiles <dotfile-path>
```
`-v` displays what changes is being made. If `-n`, a dry run will be performed.

### Removing dotfiles
In the case you wish to remove the dotfiles, run
```bash
chezmoi purge -S ~/dotfiles
```

### Re-initializing
If the prompt for GitHub mail (or similar templated parameters) are not prompted, this can be initialized by running
```bash
chezmoi init -S ~/dotfiles
```
and then the dotfiles can be applied again.

## :inbox_tray: Packages to be installed

 - [`ag`](https://github.com/ggreer/the_silver_searcher) (The Silver Searcher), for searching code. Included in full and lite package selections. Rocky 8 attempts installation through EPEL and warns if unavailable.
 - [`fzf`](https://github.com/junegunn/fzf#using-git) fuzzy searching.
 - [`fd`](https://github.com/sharkdp/fd) better `find`.
 - [`lsd`](https://github.com/Peltoche/lsd). Pretties `ls`.
 - [`tmux`](https://github.com/tmux/tmux). Terminal multiplexer.
 - [`tmux-plugins`](https://github.com/tmux-plugins/tpm). Plugins for `tmux`.
 - `vim` and [`vim plugins`](https://github.com/junegunn/vim-plug). On-the-go editor.
 - [`uv`](https://docs.astral.sh/uv/). Python version and project environment manager.
 - [`Ruff`](https://docs.astral.sh/ruff/). Python linting and formatting in full setups.
 - `zsh` and [`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh). Shell and zsh framework.
 - [`pipx`](https://pypa.github.io/pipx/). For installing pip packages in independent Python environments.
 - [`gogh`](https://gogh-co.github.io/Gogh/). Terminal colors.
 - [`zoxide`](https://github.com/ajeetdsouza/zoxide). Better change directory `cd`.

### Python environments

Full setups install Python 3.12 through uv. Ubuntu, macOS, and Windows retain pipx for CLI tools, while Rocky installs uv, Python, and Ruff without the broader pipx suite. Lite setups install uv and leave Python downloads until needed. Existing pyenv environments and Python installations are preserved, but the managed shell no longer initializes pyenv.

For a project, run `uv venv --python 3.12`, then `uv pip install -r requirements.txt` if it has a requirements file. Activate with `source .venv/bin/activate` (Zsh) or `.\.venv\Scripts\Activate.ps1` (PowerShell). uv does not replace the system `python` command.

### Python linting and formatting

Full setups install missing Ruff with `uv tool install` using managed Python 3.12. An existing Ruff on PATH is retained. Black, Flake8, and mypy remain available through pipx on Ubuntu, macOS, and Windows. Lite skips this tooling.

The Linux and macOS VSCode and Sublime settings default to Ruff linting and formatting on save, with a 79-character fallback. Project `pyproject.toml`, `ruff.toml`, or `.ruff.toml` settings take precedence. The editor fallback selects `E`, `F`, `W`, and `C90`, retaining the old VSCode rule families and `E203` exclusion. Note, Ruff has no `W503` rule. This does not reproduce every Sublime Flake8 plugin check: those settings and tools remain available, with automatic Flake8 linting disabled. Mypy remains enabled separately, and Sublime Black remains available for manual use.

The editor fallback also enables these Flake8-plugin equivalents (Ruff implements rules internally, so Flake8 package version bounds do not apply):

| Flake8 plugin | Ruff coverage |
| --- | --- |
| `flake8-bugbear` | `B` |
| `flake8-comprehensions` | `C4` |
| `flake8-use-fstring` | `UP031` and `UP032` for percent-format conversion and f-strings |
| `flake8-useless-assert` | Partial: `PLW0129` checks string literals. Existing `F631` checks tuples, and `B011` checks `assert False`. Other constant expressions and formatted-string assertions are not fully covered. |
| `flake8-broken-line` | No direct lint rule. Ruff formatting handles line continuations, but is not an equivalent diagnostic. |
| `flake8-markdown` | No equivalent lint rule for Python blocks in Markdown. Markdown formatting support is separate. |

See the [Ruff rules](https://docs.astral.sh/ruff/rules/), [broken-line tracking issue](https://github.com/astral-sh/ruff/issues/3465), and [original useless-assert checks](https://pypi.org/project/flake8-useless-assert/). The existing Flake8 tooling remains available for missing checks. These additions remain editor fallbacks. A project Ruff configuration takes precedence.

Use `ruff check .` and `ruff format .` from the CLI. To use the same 79-character preference outside the editors, set `line-length = 79` under `[tool.ruff]` in the project's `pyproject.toml`. Projects using Black can override VSCode's Python formatter or disable Sublime's `lsp_format_on_save`, and re-enable their chosen linter. GUI installers add the Ruff and mypy VSCode extensions. Sublime uses LSP-ruff. See [Ruff editor configuration](https://docs.astral.sh/ruff/editors/settings/) for project precedence.

### PowerShell Git shortcuts

The profile optionally loads `git-aliases` and `posh-git`, installed for the current user during Windows post-install setup. These preferred shortcuts also work without either module, provided Git is available:

| Shortcut | Command |
| --- | --- |
| `gco <branch>` | `git checkout <branch>` |
| `gc` | `git commit` |
| `gcmsg "message"` | `git commit --message "message"` |
| `gcam "message"` | `git commit --all --message "message"` |

Additional arguments are forwarded to Git. `gc` replaces PowerShell's `Get-Content` alias. Instead, use `Get-Content` explicitly to read files. The shared Git aliases `git cm "message"` and `git cam "message"` remain available in all shells.

### Vim plugins
Plugins used in Vim is,
 - [Material Theme](https://github.com/material-theme/vsc-community-material-theme)

### Oh-my-zsh
ohmyzsh is used as framework for managing the zsh configuration.

Following plugins are used:
 - colored-man-pages
 - copybuffer
 - copypath
 - copyfile
 - git
 - history
 - jsontools
 - sublime
 - tmux
 - z
 - zsh-autosuggestions
 - zsh-syntax-highlighting

### VSCode
VSCode is now the preferred Editor.

### Sublime Text 4
Sublime Text 4 still installed for a full Linux and MacOS setup, even tho VSCode is now the preferred editor. [Package Control](https://packagecontrol.io/) is used for managing plugins in ST4.

### Vim
A basic Vim setup is installed.

### Gogh
Terminal color provided by [Gogh](https://gogh-co.github.io/Gogh/), using the theme Afterglow.

## :alembic: Testing
To manually test that the dotfiles work as intended, you can use the Dockerfiles found in `tests`.

### :penguin: Linux: Ubuntu
Build docker image as,
```bash
docker build \
 --build-arg UBUNTU_VERSION=22.04 \
 --build-arg GIT_BRANCH=master \
 -f tests/LinuxUbuntu/Dockerfile \
 -t dotfiles-ubuntu-img --progress=plain . 
```
You can then enter the image and run the dotfiles as,
```bash
docker run -it -d --name ubuntu-dotfiles-test-1 dotfiles-ubuntu-img:latest
docker exec -it ubuntu-dotfiles-test-1 bash
```
Once inside, 
```bash
chezmoi update -n # To ensure the latest changes are picked up
chezmoi apply # To start installing dotfiles
```

To clean up, run
```bash
docker stop ubuntu-dotfiles-test-1 && docker rm ubuntu-dotfiles-test-1
```

### :penguin: Linux: Rocky 8
Build docker image as,
```bash
docker build \
 --build-arg GIT_BRANCH=master \
 -f tests/LinuxRocky8/Dockerfile \
 -t dotfiles-rocky-test --progress=plain . 
```
You can then enter the image and run the dotfiles as,
```bash
docker run -it -d --name rocky-dotfiles-test-1 dotfiles-rocky-test:latest bash
docker exec -it rocky-dotfiles-test-1 bash
```
Once inside, 
```bash
chezmoi --version || echo "Chezmoi is missing!"
chezmoi update -n # To ensure the latest changes are picked up
chezmoi apply # To start installing dotfiles
```

To clean up, run
```bash
docker stop rocky-dotfiles-test-1 && docker rm rocky-dotfiles-test-1
docker rmi dotfiles-rocky-test
```

This also runs as a GitHub actions pipeline.

### :window: Windows
To test on windows, you can run and test in [Sandbox mode](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/). The config file can be something like,
```
<Configuration>
  <MemoryInMB>8192</MemoryInMB>
  <ProcessorCount>8</ProcessorCount>
  <VGpu>Enable</VGpu>

  <LogonCommand>
    <Command>powershell.exe -ExecutionPolicy Bypass -NoLogo -NoExit</Command>
  </LogonCommand>
</Configuration>
```
The registry preparation below requires an administrator session. Run the Chezmoi bootstrap separately in a non-administrator session for the user being configured. The Windows setup only elevates its MSI helper. A Sandbox session running as administrator must switch to a non-elevated user before applying the dotfiles.

```powershell
# For faster downloading and installing
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState' -Value 0
& "$env:windir\System32\CiTool.exe" -r
```

Then, in the non-administrator session:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iex "& { $(irm 'https://get.chezmoi.io/ps1') } -b '~/bin' -- init --branch <branch-to-test> --apply hmvege"
```
The Windows workflow job is currently disabled (`if: false`). Windows installation requires manual validation.

### :green_apple: MacOS
The pipeline will run tests on the MacOS setup.

## :question: Troubleshooting

### Shell not changing
If the shell is not changed, run `chsh` and set the path to the new shell, and then re-log into your user.

### Gogh theme not activated
If terminal theme does not change, create a new profile which you names `Default` and restart the terminal and then rerun.

After installing the theme, make sure the profile is selected to be the installed one.

## :open_file_folder: File structure
```
dotfiles
├── README.md
├── bin
│  └── chezmoi
└── home
   ├── .chezmoiexternal.toml
   ├── .chezmoiignore
   ├── dot* (dotfiles)
   ├── .chezmoiscripts
   │  ├── run_once_after* (scripts that run after core installation)
   │  ├── run_once_core_linux.sh.tmpl
   │  └── run_once_core_osx.sh.tmpl
   └── dot_config
      └── dotfiles stored in ~/.config
```

## :books: Resources
- [Chezmoi documentation](https://www.chezmoi.io/)
- Order of Chezmoi
- A good introduction to Chezmoi can be found [here](https://blog.benoitj.ca/2020-06-15-how-i-use-linux-desktop-at-work-part5-dotfiles/)
- Basic usage of Chezmoi is located [here](https://pashynskykh.com/posts/chezmoi/)
- [tmux cheat sheet](https://tmuxcheatsheet.com/)

## :bulb: Inspiration
- https://github.com/renemarc/dotfiles
- https://github.com/narze/dotfiles
- https://github.com/mkasberg/dotfiles
- https://github.com/goooseman/dotfiles
- https://github.com/twpayne
- Script for installing fonts: https://gist.github.com/matthewjberger/7dd7e079f282f8138a9dc3b045ebefa0


## :balance_scale: License
MIT License.
