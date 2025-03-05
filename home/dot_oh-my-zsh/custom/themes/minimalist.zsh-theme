#!/bin/zsh
export TERM=xterm-256color

NEWLINE=$'\n'

# Git Prompt Symbols & Colors
ZSH_THEME_GIT_PROMPT_ADDED="%F{green}+%f"
ZSH_THEME_GIT_PROMPT_MODIFIED="%F{yellow}!%f"
ZSH_THEME_GIT_PROMPT_DELETED="%F{red}x%f"
ZSH_THEME_GIT_PROMPT_RENAMED="%F{cyan}→%f"
ZSH_THEME_GIT_PROMPT_UNMERGED="%F{magenta}⚡%f"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{blue}?%f"

# Right prompt (time) - Ensure it resets colors first
RPROMPT='%{$reset_color%}[%D{%H:%M:%S}]'

# Detect SSH and apply color
if [[ -n "$SSH_CONNECTION" ]]; then
    USER_HOST="%F{red}%n@%m%f "  # Light red if in SSH session
else
    USER_HOST="%F{cyan}%n@%m%f " # Cyan otherwise
fi

# Return status indicator (Green '>' if success, Red '>' if failed)
PROMPT_SYMBOL='%(?.%F{green}>.%F{red}>%f)'

# Main prompt
PS1='${USER_HOST}%F{166}%~ %F{106}$(git_current_branch)$(git_prompt_status) %{$reset_color%} ${NEWLINE}${PROMPT_SYMBOL}%{$reset_color%} '
