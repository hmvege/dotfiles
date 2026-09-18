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
   * Ubuntu 22.04
   * Ubuntu 24.04
   * Ubuntu 26.04
   * Rocky8
   * WSL 2
   * Windows 11
* Have it be easily **maintained**. I.e. changes applied at one machine, will be easily transferable to another machine.

## :scroll: Installation

### :question: Prompted Questions
During the installation, you'll be asked:
- **Mail** used for GitHub.
- Whether to perform a **minimal (lite) setup**. Lite mode provides basic shell and Vim configuration with a small optional tool set. It skips GUI apps and development suites.
- Whether to **install GUI apps** (e.g., VSCode, Sublime, fonts). There is no automatic GUI recommendation. Lite mode skips this question and installs no GUI apps.

### :feather: Lite setup for containers and VMs

Choose lite for a quick setup. Unix uses plain Zsh with history, completion, a basic prompt, and Git shortcuts. Vim uses no downloaded plugins. On Windows, an existing `_vimrc` takes precedence over the deployed `.vimrc`. PowerShell retains native listing and history search, with optional PSFzf.

Lite attempts to install,
* Git
* Vim
* fzf
* ag
* uv
* zoxide. Ordinary `cd` fallback if install fails.
* Zsh on Unix with prerequisites. Zsh provides `l`, `la`, and `lt` using native `ls`.

Full Ubuntu and macOS setups install lsd and use it for Zsh listing shortcuts when available. Lite uses native `ls`. Windows installs lsd in full mode but keeps PowerShell's native `ls` (`Get-ChildItem`). Rocky does not install lsd but honors an existing one.

Note: lite does not upgrade the system or change the login shell. Start `zsh` after applying, or keep using your current shell if Zsh could not be installed. The managed Zsh configuration requires Zsh.

macOS uses existing Homebrew and skips its bootstrap to avoid installing developer tools. Without Homebrew it still attempts standalone uv. Windows retains the PowerShell bootstrap and uses Scoop. A failed bootstrap can leave optional tools unavailable while configuration files are deployed.

Skipped tools are not automatically retried by an unchanged run_once script. Retry individual packages directly:

| Platform | Example retries |
| --- | --- |
| Ubuntu | `apt-get install -y zsh fzf silversearcher-ag zoxide` as root, or with sudo |
| Rocky 8 | `dnf install -y epel-release`, then `dnf install -y zsh fzf the_silver_searcher zoxide` as root, or with sudo |
| macOS | `brew install fzf the_silver_searcher uv zoxide` |
| Windows | `scoop install fzf ag uv zoxide` |

### :penguin: Linux
Ubuntu targets are 22.04, 24.04, and 26.04. Ubuntu 20.04 is unsupported. Runtime validation is pending.

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
Setup discovers Homebrew on Intel and Apple Silicon. It installs missing packages without a blanket upgrade. fzf setup is noninteractive and leaves shell startup files under Chezmoi control.

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
 - [`uv`](https://docs.astral.sh/uv/). Python version, project environment, and persistent CLI tool manager.
 - [`Ruff`](https://docs.astral.sh/ruff/). Python linting and formatting in full setups.
 - `zsh` and [`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh). Shell and zsh framework.
 - [`gogh`](https://gogh-co.github.io/Gogh/). Terminal colors.
 - [`zoxide`](https://github.com/ajeetdsouza/zoxide). Better change directory `cd`.

### Python environments

The dotfiles do not select a global Python. Projects choose through `requires-python`, a local `.python-version`, or `--python`. Instead, uv downloads a compatible interpreter when needed. Existing Python installations and environments are preserved.

Run `uv venv` or `uv sync` in a project. Activate with `source .venv/bin/activate` (Zsh) or `.\.venv\Scripts\Activate.ps1` (PowerShell).

### Persistent and occasional Python tools

Full Ubuntu, macOS, and Windows setups install Ruff, Black, Flake8, MkDocs, mypy, pip-tools, and pre-commit with `uv tool install --managed-python`. Rocky installs only Ruff. Lite skips Python tools.

Existing uv tool environments are preserved. Inspect their interpreters with `uv tool list --show-python`. Conflicting pipx or other commands are reported and skipped. Before migrating a pipx tool, record `pipx list --json` and `pipx runpip <tool> freeze`, then uninstall it and reapply or run `uv tool install --managed-python <tool>`.

To install with additional plugins for mypy, run:
```sh
uv tool install --managed-python --with types-requests mypy
```

Flake8 has quite a few plugins. To install them, run:
```sh
uv tool install --managed-python \
  --with flake8-broken-line --with flake8-bugbear \
  --with flake8-builtins --with flake8-docstrings \
  --with flake8-docstrings-complete --with flake8-import-order \
  --with flake8-markdown --with flake8-pie --with flake8-scream \
  --with flake8-simplify --with flake8-use-fstring \
  --with flake8-useless-assert flake8
```

### Python linting and formatting

Full setups install missing Ruff with a uv-managed Python selected by uv. Existing uv tool environments and conflicting commands are retained.

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

### Directory jumping

Zoxide provides `z` on Zsh and PowerShell. `zi` opens an fzf picker. Full and lite setups attempt installation on all platforms. If it fails, use ordinary `cd`. Lite tolerates optional installation failures. Full setup can still stop on installation failures.

If applying dotfiles on a system previously using the `z` plugin, one can import `zsh-z`'s history to `zoxide` via,
```sh
zoxide import --from=z "${ZSHZ_DATA:-$HOME/.z}"
```

The old database is preserved. For a skipped installation, retry with `sudo apt-get install zoxide`, `brew install zoxide`, or `scoop install zoxide`. On Rocky, try `sudo dnf install zoxide` or the [upstream installer](https://github.com/ajeetdsouza/zoxide#installation).

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
Full Unix setups use ohmyzsh for Zsh configuration. Lite uses plain Zsh.

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
 - zsh-autosuggestions
 - zsh-syntax-highlighting

### VSCode
VSCode is now the preferred Editor.

### Sublime Text 4
Sublime Text 4 still installed for a full Linux and MacOS setup, even tho VSCode is now the preferred editor. [Package Control](https://packagecontrol.io/) is used for managing plugins in ST4.

### Vim
A basic Vim setup is installed.

### Gogh
Ubuntu enables Gogh in full GUI mode, including WSL with GNOME Terminal and a graphical D-Bus session. Lite skips it. This does not theme Windows Terminal.

Terminal color provided by [Gogh](https://gogh-co.github.io/Gogh/), using the theme Afterglow.

## :alembic: Testing
Pull requests run template, syntax, whitespace, and workflow smoke checks without installing packages. Pushes to `master` run Linux, macOS, and WSL2 installation coverage. Windows installation runs only by manual workflow dispatch. Ubuntu GUI desktop behavior is accepted manually on 22.04, 24.04, and 26.04.

See [Dotfiles testing](docs/dotfiles-testing.md) for the matrix, local commands, repeat-apply policy, failure logs, and manual VMware/Windows/WSLg/macOS checklists.

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
