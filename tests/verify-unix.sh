#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <lite|full-cli|full-gui> [--configuration-only]" >&2
    exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
mode="$1"
# Only the lite resilience cases may omit optional tools. Normal matrix cases
# must prove those tools were installed. This flag never changes installation.
configuration_only=false
if [ "$#" -eq 2 ]; then
    [ "$mode" = lite ] && [ "$2" = --configuration-only ] || usage
    configuration_only=true
fi
case "$mode" in
    lite|full-cli|full-gui) ;;
    *) usage ;;
esac

fail() {
    echo "VERIFY FAILED: $*" >&2
    exit 1
}

require_file() {
    [ -f "$1" ] || fail "expected deployed file: $1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "expected command: $1"
}

case "$(uname -s)" in
    Darwin)
        platform=macos
        ;;
    Linux)
        [ -r /etc/os-release ] || fail "cannot identify Linux distribution"
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}" in
            ubuntu) platform=ubuntu ;;
            rocky) platform=rocky ;;
            *) fail "unsupported Linux distribution: ${ID:-unknown}" ;;
        esac
        if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
            platform=wsl
        fi
        ;;
    *) fail "unsupported Unix platform: $(uname -s)" ;;
esac

require_file "$HOME/.gitconfig"
require_file "$HOME/.vimrc"
require_file "$HOME/.zshrc"

export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$PATH"
required=(git)
if [ "$configuration_only" = false ]; then
    required+=(vim zsh fzf ag uv zoxide)
fi

if [ "$mode" = lite ]; then
    if [ "$configuration_only" = false ]; then
        required+=(bat)
    fi
    [ ! -e "$HOME/.tmux.conf" ] || fail "lite mode deployed .tmux.conf"
    [ ! -e "$HOME/.oh-my-zsh" ] || fail "lite mode installed Oh My Zsh"
    [ ! -e "$HOME/.config/Code" ] || fail "lite mode deployed VSCode settings"
    [ ! -e "$HOME/.config/sublime-text" ] || fail "lite mode deployed Sublime settings"
    [ ! -e "$HOME/Library/Application Support/Code" ] || fail "lite mode deployed macOS editor settings"
    [ ! -e "$HOME/Library/Application Support/Sublime Text" ] || fail "lite mode deployed macOS Sublime settings"
    [ ! -e "$HOME/.vim/autoload/plug.vim" ] || fail "lite installed Vim plugins"
    if command -v uv >/dev/null 2>&1; then
        [ -z "$(uv tool list)" ] || fail "lite provisioned uv tools"
        python_dir="$(uv python dir)"
        [ ! -d "$python_dir" ] || [ -z "$(find "$python_dir" -name 'python*' -type f -print -quit)" ] ||
            fail "lite downloaded managed Python"
    fi
else
    case "$platform" in
        rocky)
            required+=(jq ruff)
            ;;
        ubuntu|wsl)
            required+=(bat codex fd jq lsd ruff tmux)
            ;;
        macos)
            required+=(bat codex fd jq lsd ruff tmux)
            ;;
    esac
fi

for command_name in "${required[@]}"; do
    require_command "$command_name"
done

if [ "$mode" != lite ] && [ "$platform" != rocky ]; then
    codex --version || fail 'Codex cannot report its version'
    if [ "$(id -un)" != root ]; then
        case "$(uname -s)" in
            Darwin) login_shell="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')" ;;
            Linux) login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)" ;;
        esac
        [ "${login_shell##*/}" = zsh ] && [ -x "$login_shell" ] || fail "saved login shell is not executable Zsh: $login_shell"
        grep -Fqx "$login_shell" /etc/shells || fail "saved Zsh is not registered: $login_shell"
    fi
fi

if command -v zsh >/dev/null 2>&1; then
    if [ "$mode" = lite ]; then
        zsh -dfc '
            source "$HOME/.zshrc" || exit 1
            [[ "$aliases[l]" = "ls -l" ]] || exit 1
            if command -v fzf >/dev/null; then
                bindkey "^R" | grep -q lite-history-search
            else
                bindkey "^R" | grep -q history-incremental-search-backward
            fi
        '
    else
        zsh -dfc 'source "$HOME/.zshrc" && command -v zoxide >/dev/null && alias gst >/dev/null'
        if command -v lsd >/dev/null 2>&1; then
            zsh -dfc 'source "$HOME/.zshrc"; alias l | grep -q lsd'
        fi
    fi
fi

if [ "$mode" != lite ] && command -v uv >/dev/null 2>&1; then
    uv_tool_bin="$(uv tool dir --bin)"
    uv_inventory="$(uv tool list --show-python)"
    [ -n "$uv_inventory" ] || fail "uv tool inventory is empty"

    uv_commands=(ruff)
    if [ "$platform" != rocky ]; then
        uv_commands+=(black flake8 mkdocs mypy pip-compile pre-commit)
    fi
    for command_name in "${uv_commands[@]}"; do
        command_path="$(command -v "$command_name" 2>/dev/null || true)"
        [ -n "$command_path" ] || fail "missing uv tool command: $command_name"
        case "$command_path" in
            "$uv_tool_bin"/*) ;;
            *) fail "$command_name is not owned by uv: $command_path" ;;
        esac
    done
    grep -qi python <<< "$uv_inventory" || fail "uv tool interpreters were not reported"
    tool_root="$(uv tool dir)"
    managed_python_root="$(uv python dir)"
    packages=(ruff)
    [ "$platform" = rocky ] || packages+=(black flake8 mkdocs mypy pip-tools pre-commit)
    for package in "${packages[@]}"; do
        # sys.base_prefix identifies the interpreter underlying the tool venv.
        base_prefix="$("$tool_root/$package/bin/python" -c 'import sys; print(sys.base_prefix)')"
        case "$base_prefix" in
            "$managed_python_root"/*) ;;
            *) fail "$package uses unmanaged Python: $base_prefix" ;;
        esac
    done
fi

if [ "$mode" = full-gui ]; then
    case "$platform" in
        ubuntu|wsl)
            require_file "$HOME/.config/Code/User/settings.json"
            require_file "$HOME/.config/sublime-text/Packages/User/Preferences.sublime-settings"
            require_file "$HOME/.config/sublime-text/Installed Packages/Package Control.sublime-package"
            require_command subl
            require_command smerge
            # Missing snap/VSCode is a coverage failure, not a successful GUI install.
            require_command code
            extensions="$(code --list-extensions)"
            for extension in charliermarsh.ruff ms-python.mypy-type-checker; do
                grep -Fqx "$extension" <<< "$extensions" || fail "missing extension: $extension"
            done
            find "$HOME/.local/share/fonts" -type f -print -quit | grep -q . || \
                fail "no installed font files found"
            if [ -n "${DOTFILES_INSTALL_LOG:-}" ]; then
                grep -Fq 'Skipping Gogh: GNOME Terminal and a graphical D-Bus session are required.' \
                    "$DOTFILES_INSTALL_LOG" || fail "Gogh did not report a safe headless skip"
            fi
            ;;
        macos)
            require_file "$HOME/Library/Application Support/Code/User/settings.json"
            require_file "$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
            require_file "$HOME/Library/Application Support/Sublime Text/Installed Packages/Package Control.sublime-package"
            require_command code
            require_command subl
            require_command smerge
            extensions="$(code --list-extensions)"
            for extension in charliermarsh.ruff ms-python.mypy-type-checker; do
                grep -Fqx "$extension" <<< "$extensions" || fail "missing extension: $extension"
            done
            ;;
        *) fail "full GUI verification is not supported on $platform" ;;
    esac
fi

echo "Verified $platform $mode dotfiles for $(id -un) (configuration-only: $configuration_only)."
