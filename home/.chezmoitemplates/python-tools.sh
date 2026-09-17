# uv owns newly provisioned Python CLI tools. Existing non-uv commands are
# preserved and reported so their environments can be migrated explicitly.
export PATH="$HOME/.local/bin:$PATH"
export UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-$HOME/.local/bin}"
uv_tool_bin="$(uv tool dir --bin)"
export PATH="$uv_tool_bin:$PATH"
uv_tool_state="$(uv tool list)"

install_uv_tool() {
    local package="$1" command="$2" existing
    shift 2

    if grep -q "^${package} v" <<< "$uv_tool_state"; then
        echo "$package is already installed with uv; preserving its environment."
        return
    fi

    if existing="$(command -v "$command" 2>/dev/null)"; then
        echo "Warning: skipping uv tool install $package because $command is already provided by $existing." >&2
        echo "Record and remove the existing tool explicitly before migrating it to uv. See README.md." >&2
        return
    fi

    uv tool install --managed-python "$@" "$package"
}

install_uv_tool ruff ruff
install_uv_tool black black
install_uv_tool flake8 flake8 \
    --with flake8-broken-line \
    --with flake8-bugbear \
    --with flake8-builtins \
    --with flake8-docstrings \
    --with flake8-docstrings-complete \
    --with flake8-import-order \
    --with flake8-markdown \
    --with flake8-pie \
    --with flake8-scream \
    --with flake8-simplify \
    --with flake8-use-fstring \
    --with flake8-useless-assert
install_uv_tool mkdocs mkdocs
install_uv_tool mypy mypy --with types-requests
install_uv_tool pip-tools pip-compile
install_uv_tool poetry poetry
install_uv_tool pre-commit pre-commit
