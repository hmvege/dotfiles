# Optional directory jumping. The shell keeps ordinary cd if installation fails.
export PATH="$HOME/.local/bin:$PATH"
if ! command -v zoxide >/dev/null 2>&1; then
    {{ if eq .chezmoi.osRelease.id "ubuntu" -}}
    if ! sudo apt-get install -y zoxide; then
    {{ else -}}
    if ! sudo dnf -y install zoxide; then
    {{ end -}}
        if ! curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            echo "WARNING: zoxide installation failed. Use ordinary cd." >&2
        fi
    fi
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "WARNING: zoxide is unavailable on PATH. Use ordinary cd." >&2
    fi
fi
