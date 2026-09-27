# Plain Zsh, with no downloaded framework or plugins.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory histignoredups
autoload -Uz compinit
compinit -i
bindkey -e
PROMPT='%n@%m:%~%# '

export EDITOR=vim
alias l='ls -l'
alias la='ls -lah'
alias lt='ls -lt'
alias g='git'
alias gst='git status'
alias ga='git add'
alias gd='git diff'
alias gco='git checkout'
alias gc='git commit'
alias gcmsg='git commit --message'
alias gcam='git commit --all --message'

# Ctrl-R falls back to Zsh's own search when fzf is missing.
bindkey '^R' history-incremental-search-backward
if command -v fzf >/dev/null 2>&1; then
    lite-history-search() {
        local selected
        selected=$(fc -rl -n 1 | fzf --height 40% --reverse --query "$LBUFFER") || return 0
        BUFFER="$selected"
        CURSOR=${#BUFFER}
        zle reset-prompt
    }
    zle -N lite-history-search
    bindkey '^R' lite-history-search
fi
