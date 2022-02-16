# [WIP] Dotfiles
*This dotfiles repository is a work in progress.*

Dotfiles repository for `hmvege`, managed with [Chezmoi](https://github.com/twpayne/chezmoi)

## TODO
<!-- :ballot_box_with_check:  -->
:ballot_box_with_check: Verify that setup runs.

:ballot_box_with_check: Add Sublime settings.

:ballot_box_with_check: Will use default color schemes for new installed, or manually install set up Material Theme.

:black_square_button: Add tmux configuration file. Make default layout when opening tmux?

:black_square_button: Fix final bugs in setup(message script does not work)

:black_square_button: Add chsh to setup scripts

:black_square_button: Update installation tools. Split into two copyable commands

:black_square_button: Add MacOS installation script `run_once_core_osx.sh`

:black_square_button: Split core setup `.tmpl` scripts into separate scripts.

:black_square_button: Ensure pyenv, pipx, ect works after setup.


## :dart: Goals
The goal for this dotfiles project repository, is following,
* Have a, as close to as possible, fully **automatized dotfiles setup**.
* Have the setup **install packages automatically**.
* Have a **cross-platform** dotfiles setup, working for both MacOS and Ubuntu.
* Have it be easily **maintained**. I.e. changes applied at one machine, will be easily transferable to another machine.

## :scroll: Installation
Install Chezmoi and initialize by running,

```bash
$ apt-get update && apt-get install -y curl sudo
$ sh -c "$(curl -fsLS chezmoi.io/get)" -- -b "$HOME/dotfiles/bin" init --apply -S ~/dotfiles hmvege
```

which will download the Chezmoi binary to `$HOME/bin`, and use `~/dotfiles` as source for Chezmoi by downloading this repository to this location.

### Updating dotfiles
Pull latest changes from repository.
```bash
$ chezmoi update
```

### Apply changes
Apply the changes made to the dotfiles made through `chezmoi edit [$FILE]`
```bash
$ chezmoi -v apply
```
`-v` displays what changes is being made. If `-n`, a dry run will be performed.


### Add changes to Chezmoi dotfiles
Apply the changes made to the dotfiles made through `chezmoi edit [$FILE]`
```bash
$ chezmoi add -S $(readlink -f ~/dotfiles/home) <dotfile-path>
```
`-v` displays what changes is being made. If `-n`, a dry run will be performed.


### Removing dotfiles
In the case you wish to remove the dotfiles, run
```bash
$ chezmoi purge
```

## :inbox_tray: Packages to be installed

 - [`fasd`](https://github.com/clvv/fasd)
 - [`fzf`](https://github.com/junegunn/fzf#using-git)
 - [`lsd`](https://github.com/Peltoche/lsd)
 - [`tmux`](https://github.com/tmux/tmux)
 - [`tmux-plugins`](https://github.com/tmux-plugins/tpm)
 - `vim` and [`vim plugins`](https://github.com/junegunn/vim-plug)
 - [`pyenv` and `pyenv-virtualenv`](https://github.com/pyenv)
 - `zsh` and [`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh)
 - [`pipx`](https://pypa.github.io/pipx/)


### Vim plugins
Plugins used in Vim is,
 - [Material Theme](https://github.com/material-theme/vsc-community-material-theme)


### Oh-my-zsh
ohmyzsh is used as framework for managing the zsh configuration.

Following plugins are used:
 - pass

### Sublime Text 4
Currently, Sublime Text 4 is my preferred editor, with Vim supporting me on the side every now and then. [Package Control](https://packagecontrol.io/) is used for managing plugins.

Plugins used:
 - A File Icon
 - Color Highlight
 - ColorPicker
 - DockBlockr 2021 (DoxyDoxygen powered)
 - Dockerfile Syntax Highlighting
 - Figlet Big ASCII Text
 - GithubEmoji
 - Gruvebox Material Theme
 - Indent XML
 - MarkdownPreview
 - Material Theme
 - PackageResourceViewer
 - python-black
 - SublimeCodeIntel
 - SublimeLinter
 - SublimeLinter-contrib-mypy
 - SublimeLinter-flake8
 - TodoReview
 - TOML

Note these packages may need to be downloaded manually.

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
<!-- - https://github.com/tordks/.dotfiles -->
- https://github.com/renemarc/dotfiles
- https://github.com/narze/dotfiles
- https://github.com/mkasberg/dotfiles
- https://github.com/goooseman/dotfiles
- https://github.com/twpayne
- Script for installing fonts: https://gist.github.com/matthewjberger/7dd7e079f282f8138a9dc3b045ebefa0
