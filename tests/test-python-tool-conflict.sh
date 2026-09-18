#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/home/.local/bin" "$scratch/uv-tools"

config="$scratch/config.toml"
printf '[data]\nemail = "testmail@example.com"\nlite = false\ngui = false\n' > "$config"
chezmoi -S "$repo_root/home" -c "$config" execute-template \
    < "$repo_root/home/.chezmoitemplates/python-tools.sh" > "$scratch/python-tools.sh"

cat > "$scratch/bin/uv" <<'EOF'
#!/bin/sh
if [ "$1 $2 $3" = "tool dir --bin" ]; then
    printf '%s\n' "$MOCK_UV_TOOL_BIN"
elif [ "$1 $2" = "tool list" ]; then
    exit 0
elif [ "$1 $2" = "tool install" ]; then
    printf '%s\n' "$*" >> "$MOCK_UV_LOG"
else
    exit 1
fi
EOF
cat > "$scratch/bin/ruff" <<'EOF'
#!/bin/sh
echo unrelated-ruff
EOF
chmod +x "$scratch/bin/uv" "$scratch/bin/ruff"

HOME="$scratch/home" \
PATH="$scratch/bin:/usr/bin:/bin" \
MOCK_UV_TOOL_BIN="$scratch/uv-tools" \
MOCK_UV_LOG="$scratch/uv.log" \
    bash "$scratch/python-tools.sh"

[ "$(PATH="$scratch/bin:/usr/bin:/bin" ruff)" = unrelated-ruff ] || {
    echo "Existing ruff command was overwritten" >&2
    exit 1
}
if grep -Eq 'tool install .* ruff$' "$scratch/uv.log"; then
    echo "uv attempted to overwrite an unrelated ruff command" >&2
    exit 1
fi
grep -Eq 'tool install .* black$' "$scratch/uv.log" || {
    echo "Control tool installation was not attempted" >&2
    exit 1
}

echo "Existing non-uv command conflict was preserved."
