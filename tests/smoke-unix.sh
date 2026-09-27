#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

command -v chezmoi >/dev/null 2>&1 || {
    echo "chezmoi is required for template smoke tests" >&2
    exit 1
}
command -v zsh >/dev/null 2>&1 || {
    echo "zsh is required for template smoke tests" >&2
    exit 1
}

sublime_user_dirs=(
    "$repo_root/home/dot_config/private_sublime-text/private_Packages/private_User"
    "$repo_root/home/private_Library/private_Application Support/private_Sublime Text/private_Packages/private_User"
)
legacy_sublime_dirs=(
    "$repo_root/home/dot_config/private_sublime-text-3"
    "$repo_root/home/private_Library/private_Application Support/private_Sublime Text 3"
)
for user_dir in "${sublime_user_dirs[@]}"; do
    package_settings="$user_dir/Package Control.sublime-settings"
    if [ ! -f "$package_settings" ]; then
        echo "Missing ST4 Package Control settings: $package_settings" >&2
        exit 1
    fi
    grep -Fq '"LSP-ruff"' "$package_settings" || {
        echo "ST4 Package Control settings do not install LSP-ruff: $package_settings" >&2
        exit 1
    }
    if grep -Fq '"AutoPEP8"' "$package_settings"; then
        echo "Obsolete AutoPEP8 package remains listed: $package_settings" >&2
        exit 1
    fi
done
for legacy_dir in "${legacy_sublime_dirs[@]}"; do
    if [ -d "$legacy_dir" ]; then
        echo "Legacy ST3 source directory remains: $legacy_dir" >&2
        exit 1
    fi
done

render() {
    local source_file="$1" destination="$2" lite="$3" gui="$4"
    local config="$scratch/config-$lite-$gui.toml"
    printf '[data]\nemail = "testmail@example.com"\nlite = %s\ngui = %s\n' \
        "$lite" "$gui" > "$config"
    # Override only platform facts, keeping Chezmoi's real paths and include data.
    # This exercises guarded Rocky and WSL branches without installing packages.
    {
        case "$platform" in
            macos)
                printf '%s' '{{ $_ := set .chezmoi "os" "darwin" }}'
                ;;
            rocky)
                printf '%s' '{{ $_ := set .chezmoi "osRelease" (dict "id" "rocky" "versionID" "8") }}'
                ;;
            wsl)
                printf '%s' '{{ $_ := set .chezmoi "osRelease" (dict "id" "ubuntu" "versionID" "24.04") }}{{ $_ := set .chezmoi.kernel "osrelease" "6.6.0-microsoft-standard-WSL2" }}'
                ;;
        esac
        cat "$source_file"
    } | chezmoi -S "$repo_root/home" -c "$config" execute-template > "$destination"
}

platforms=(native)
if [ "$(uname -s)" = Linux ]; then
    platforms+=(rocky wsl macos)
fi
for platform in "${platforms[@]}"; do
    for case_name in lite full-cli full-gui; do
        case "$case_name" in
            lite) lite=true; gui=false ;;
            full-cli) lite=false; gui=false ;;
            full-gui) lite=false; gui=true ;;
        esac

        while IFS= read -r template; do
            rendered="$scratch/${platform}-${case_name}-$(basename "$template" .tmpl)"
            render "$template" "$rendered" "$lite" "$gui"
            bash -n "$rendered"
        done < <(find "$repo_root/home/.chezmoiscripts" -type f -name '*.sh.tmpl' -print | sort)

        rendered_zsh="$scratch/${platform}-${case_name}-zshrc"
        render "$repo_root/home/dot_zshrc.tmpl" "$rendered_zsh" "$lite" "$gui"
        zsh -n "$rendered_zsh"
    done
    echo "Rendered and syntax-checked $platform templates in all three modes."
done

bash "$repo_root/tests/test-python-tool-conflict.sh"
bash "$repo_root/tests/test-ubuntu-command-links.sh"

echo "Unix template smoke checks passed."
