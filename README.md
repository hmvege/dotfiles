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
- Whether to **install GUI apps** (e.g., VSCode, Sublime, fonts), with auto-detected recommendation.
- Whether to perform a **minimal (lite) setup**. If `lite` mode is selected, GUI apps will automatically be skipped (e.g. VSCode, Sublime, tmux, Gogh etc.).
- **Mail** used for GitHub.

### :penguin: Linux
Install Chezmoi and initialize, ensure `curl` and `sudo` is installed,
```bash
apt-get update && apt-get install -y curl sudo
```
then download and apply the dotfiles,
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --apply hmvege
```
which will download the Chezmoi binary to `$HOME/bin`, and use `~/dotfiles` as source for Chezmoi by downloading this repository to this location.

### :green_apple:	MacOS
On MacOS, you should be able to install Chezmoi via
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/" init -S ~/dotfiles --apply hmvege
```

### :window: Windows
The dotfiles for Windows is targeting PowerShell. Install Chezmoi via,
```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '~/bin' -- init -S ~/dotfiles --apply hmvege"
```
The dotfiles setup will download the latest PowerShell 7.4.1.

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

 - [`fzf`](https://github.com/junegunn/fzf#using-git) fuzzy searching.
 - [`fd`](https://github.com/sharkdp/fd) better `find`.
 - [`lsd`](https://github.com/Peltoche/lsd). Pretties `ls`.
 - [`tmux`](https://github.com/tmux/tmux). Terminal multiplexer.
 - [`tmux-plugins`](https://github.com/tmux-plugins/tpm). Plugins for `tmux`.
 - `vim` and [`vim plugins`](https://github.com/junegunn/vim-plug). On-the-go editor.
 - [`pyenv` and `pyenv-virtualenv`](https://github.com/pyenv). Python virtual environment handler.
 - `zsh` and [`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh). Shell and zsh framework.
 - [`pipx`](https://pypa.github.io/pipx/). For installing pip packages in independent Python environments.
 - [`gogh`](https://gogh-co.github.io/Gogh/). Terminal colors.
 - [`zoxide`](https://github.com/ajeetdsouza/zoxide). Better change directory `cd`.

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
 -f tests/LinuxRocky/Dockerfile \
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
To test on windows, you can run and test in [Sandbox mode](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/. The config file can be something like,
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
Once started, run the following commands
```
# For faster downloading and installing
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState' -Value 0
& "$env:windir\System32\CiTool.exe" -r

Set-ExecutionPolicy Bypass -Scope Process -Force
iex "& { $(irm 'https://get.chezmoi.io/ps1') } -b '~/bin' -- init --branch <branch-to-test> --apply hmvege"
```
The pipeline will also run tests on the windows setup.

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
