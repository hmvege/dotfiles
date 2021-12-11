# [WIP] Dotfiles
*This dotfiles repository is a work in progress.*

Dotfiles repository for `hmvege`, managed with [Chezmoi](https://github.com/twpayne/chezmoi)

## TODO
<!-- :ballot_box_with_check:  -->
:black_square_button: Verify that setup runs.
:black_square_button: Add Sublime settings.
:black_square_button: Add MacOS installation script `run_once_core_osx.sh`
:black_square_button: Split setup `.tmpl` scripts into separate scripts.


## :dart: Goals
The goal for this dotfiles project repository, is following,
* Have a, as close to as possible, fully **automatized dotfiles setup**.
* Have the setup **install packages automatically**.
* Have a **cross-platform** dotfiles setup, working for both MacOS and Ubuntu.
* Have it be easily **maintained**. I.e. changes applied at one machine, will be easily transferable to another machine.

## :scroll: Installation
Download, install Chezmoi, and initialize,

```bash
$ sh -c "$(curl -fsLS https://git.io/chezmoi)" -- init --apply <username>
```

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

### Removing dotfiles
In the case you wish to remove the dotfiles, run
```bash
$ chezmoi purge
```

##  Packages to be installed

 - [`fasd`](https://github.com/clvv/fasd)
 - [`fzf`](https://github.com/junegunn/fzf#using-git)
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
 - DockBlockr 2021
 - Dockerfile Syntax Highlighting
 - Figlet Big ASCII Text
 - Indent XML
 - MarkdownPreview
 - Material Theme
 - PackageResourceViewer
 - SublimeLinter
 - SublimeLinter-contrib-mypy
 - SublimeLinter-flake8
 - TodoReview


## :open_file_folder: File structure
```
dotfiles
| README.md
| install.sh
│ Makefile
└─── chezmoi                # All dotfiles will be stored here
│   |   run_once_core.sh    # Install relevant packages
|   |   ...                 # Dotfiles 
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