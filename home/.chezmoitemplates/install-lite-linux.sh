# Small, optional package set for disposable containers and VMs.
export PATH="$HOME/.local/bin:$PATH"
privilege=()
can_install=true
if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        privilege=(sudo -n)
    else
        can_install=false
        echo "Skipping system packages: root or passwordless sudo is required for unattended lite setup."
    fi
fi

{{ if eq .chezmoi.osRelease.id "ubuntu" -}}
install_package=(apt-get install -y --no-install-recommends)
packages=(ca-certificates curl git zsh vim fzf silversearcher-ag zoxide)
{{ else -}}
install_package=(dnf install -y --setopt=install_weak_deps=False)
packages=(ca-certificates curl git zsh vim-enhanced fzf the_silver_searcher zoxide)
{{ end -}}

if [ "$can_install" = true ]; then
    {{ if eq .chezmoi.osRelease.id "ubuntu" -}}
    if ! "${privilege[@]}" apt-get update; then
        echo "Warning: package index refresh failed. Trying the available indexes." >&2
    fi
    {{ else -}}
    # EPEL supplies fzf and ag on Rocky. Other packages can still succeed without it.
    if ! "${privilege[@]}" dnf install -y epel-release; then
        echo "Warning: EPEL is unavailable. Some optional tools may be skipped." >&2
    fi
    {{ end -}}
    for package in "${packages[@]}"; do
        {{ if eq .chezmoi.osRelease.id "ubuntu" -}}
        if [ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" = "install ok installed" ]; then
            continue
        fi
        {{ else -}}
        if rpm -q "$package" >/dev/null 2>&1; then
            continue
        fi
        {{ end -}}
        if ! "${privilege[@]}" "${install_package[@]}" "$package"; then
            echo "Warning: could not install $package. Continuing lite setup." >&2
        fi
    done
fi

{{ includeTemplate "install-uv.sh" . }}

echo "Lite setup attempted. Start zsh if installed, otherwise keep using your current shell."
