#!/bin/zsh
export TERM=xterm-256color

NEWLINE=$'\n'

# Git Prompt Symbols
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[orange]%} ✈"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[orange]%} ✭"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[orange]%} ➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[orange]%} ✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[orange]%} ✱"

# Right prompt (time) - Ensure it resets colors first
RPROMPT='%{$reset_color%}[%D{%H:%M:%S}]'

# Detect SSH and apply color
if [[ -n "$SSH_CONNECTION" ]]; then
    SSH_INFO="%F{red}%n@%m%f "  # Light red if in SSH session
else
    SSH_INFO=""
fi

# Return status indicator (Green '>' if success, Red '>' if failed)
PROMPT_SYMBOL='%(?.%F{green}>.%F{red}>%f)'

# Main prompt (fixing virtualenv evaluation inside PS1)
PS1='${SSH_INFO}$(if [[ -n "$VIRTUAL_ENV" ]]; then echo "%F{blue}(${VIRTUAL_ENV:t})%f "; fi)%F{166}%~ %F{106}$(git_current_branch)$(git_prompt_status) %{$reset_color%} ${NEWLINE}${PROMPT_SYMBOL} '
