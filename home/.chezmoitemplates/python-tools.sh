# Keep pipx as the owner of the existing CLI tools; uv manages Python and Ruff.
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.12
python_for_tools="$(uv python find --managed-python 3.12)"
uv_tool_bin="$(uv tool dir --bin)"
export PATH="$uv_tool_bin:$PATH"
if ! command -v ruff >/dev/null 2>&1; then
    uv tool install --python "$python_for_tools" ruff
fi
if ! command -v pipx >/dev/null 2>&1; then
    uv tool install --python "$python_for_tools" pipx
fi
pipx ensurepath
pipx_bin="$(pipx environment --value PIPX_BIN_DIR)"
export PATH="$pipx_bin:$PATH"

pipx_packages=(black flake8 mkdocs mypy pip-tools poetry pre-commit)
pipx_state="$(pipx list --json)"
for pkg in "${pipx_packages[@]}"; do
    if ! jq -e --arg package "$pkg" '.venvs | has($package)' <<< "$pipx_state" >/dev/null; then
        pipx install --python "$python_for_tools" "$pkg"
    else
        echo "$pkg is already installed with pipx."
    fi
done

pipx inject mypy types-requests
flake8_packages=(
    flake8-broken-line
    flake8-bugbear
    flake8-builtins
    flake8-docstrings
    flake8-docstrings-complete
    flake8-import-order
    flake8-markdown
    flake8-pie
    flake8-scream
    flake8-simplify
    flake8-use-fstring
    flake8-useless-assert
)
pipx inject flake8 "${flake8_packages[@]}"
