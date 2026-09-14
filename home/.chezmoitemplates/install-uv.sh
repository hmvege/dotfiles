# Install uv without letting its installer rewrite managed shell profiles.
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv >/dev/null 2>&1; then
    if curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh; then
        command -v uv >/dev/null 2>&1 || { echo "uv is missing after installation." >&2; exit 1; }
    else
{{ if .lite -}}
        echo "WARNING: uv installation failed; continuing the lite setup." >&2
{{ else -}}
        echo "uv installation failed." >&2
        exit 1
{{ end -}}
    fi
fi
