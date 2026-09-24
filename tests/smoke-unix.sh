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

render() {
    local source_file="$1" destination="$2" lite="$3" gui="$4"
    local config="$scratch/config-$lite-$gui.toml"
    printf '[data]\nemail = "testmail@example.com"\nlite = %s\ngui = %s\n' \
        "$lite" "$gui" > "$config"
    # Override only platform facts, keeping Chezmoi's real paths and include data.
    # This exercises guarded Rocky and WSL branches without installing packages.
    {
        case "$platform" in
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
    platforms+=(rocky wsl)
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
