saved_login_shell() {
    local user="$1" record shell
    case "$(uname -s)" in
        Linux)
            record="$(getent passwd "$user")" || return 1
            shell="$(printf '%s\n' "$record" | cut -d: -f7)"
            ;;
        Darwin)
            record="$(dscl . -read "/Users/$user" UserShell)" || return 1
            shell="${record##*UserShell: }"
            ;;
        *) return 1 ;;
    esac
    case "$shell" in /*) printf '%s\n' "$shell" ;; *) return 1 ;; esac
}

registered_zsh() {
    [ "${1##*/}" = zsh ] && [ -x "$1" ] && grep -Fqx -- "$1" /etc/shells
}

configure_login_shell() {
    local user saved target verified
    local sudo_args=()
    user="$(id -un 2>/dev/null)" || user=
    if [ -z "$user" ]; then
        echo 'Warning: cannot identify the account. Login shell unchanged.' >&2
        return 0
    fi
    if [ "$user" = root ]; then
        echo 'Skipping login-shell changes for root.'
        return 0
    fi
    if ! saved="$(saved_login_shell "$user")"; then
        echo "Warning: cannot read the saved login shell for $user. Check its passwd record, then apply again." >&2
        return 0
    fi
    if registered_zsh "$saved"; then
        printf 'Saved login shell unchanged for %s: %s\n' "$user" "$saved"
        return 0
    fi

    target=/bin/zsh
    if [ "$(uname -s)" = Linux ] && registered_zsh /usr/bin/zsh; then
        target=/usr/bin/zsh
    fi
    if ! registered_zsh "$target"; then
        echo "Warning: no executable, registered system Zsh. Install Zsh and check /etc/shells, then apply again." >&2
        return 0
    fi
    if [ ! -t 0 ] || [ ! -t 1 ]; then sudo_args=(-n); fi
    if sudo "${sudo_args[@]}" chsh -s "$target" "$user" &&
        verified="$(saved_login_shell "$user")" && [ "$verified" = "$target" ]; then
        printf 'Saved login shell changed for %s: %s\n' "$user" "$verified"
        return 0
    fi
    echo "Warning: could not change the login shell for $user." >&2
    printf 'Retry manually: sudo chsh -s %q %q\n' "$target" "$user" >&2
}

report_login_shell() {
    local user saved
    user="$(id -un 2>/dev/null)" || user=unknown
    saved="$(saved_login_shell "$user" 2>/dev/null)" || saved=unknown
    printf 'Saved login shell for %s: %s\n' "$user" "$saved"
    if [ "$user" = root ]; then
        printf '%s\n' 'Root login shell was not changed.'
    elif ! registered_zsh "$saved"; then
        printf '%s\n' 'Zsh login setup is unchanged or unverified. Review the shell-setup messages above.'
    else
        printf '%s\n' 'The current terminal remains unchanged. Log out and log in to use the saved login shell.'
        printf '%s\n' 'If a new terminal uses another shell, check its terminal-profile command override.'
    fi
}
