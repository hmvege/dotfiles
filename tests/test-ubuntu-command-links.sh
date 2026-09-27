#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
helper="$repo_root/home/.chezmoitemplates/link-ubuntu-command.sh"

fail() {
    echo "Command link test failed: $*" >&2
    exit 1
}

[ -f "$helper" ] || fail "shared command-link helper is missing"
bash_path="$(command -v bash)"
mkdir -p "$scratch/bin"
# Isolate PATH from any bat installed on the test host.
for tool in mkdir ln; do
    ln -s "$(command -v "$tool")" "$scratch/bin/$tool"
done
printf '#!/bin/sh\necho test-bat\n' > "$scratch/bin/batcat"
chmod +x "$scratch/bin/batcat"

run_link() {
    HOME="$scratch/home" PATH="$scratch/home/.local/bin:$scratch/bin" \
        "$bash_path" -euc 'source "$1"; link_ubuntu_command batcat bat' bash "$helper"
}

run_link
[ "$(readlink "$scratch/home/.local/bin/bat")" = "$scratch/bin/batcat" ] || fail "link target"
[ "$("$scratch/home/.local/bin/bat")" = test-bat ] || fail "linked command cannot run"
run_link
[ "$(readlink "$scratch/home/.local/bin/bat")" = "$scratch/bin/batcat" ] || fail "repeat changed link"

rm "$scratch/home/.local/bin/bat"
printf 'user file\n' > "$scratch/home/.local/bin/bat"
run_link
[ "$(cat "$scratch/home/.local/bin/bat")" = 'user file' ] || fail "existing file changed"

rm "$scratch/home/.local/bin/bat"
ln -s "$scratch/missing" "$scratch/home/.local/bin/bat"
run_link
[ "$(readlink "$scratch/home/.local/bin/bat")" = "$scratch/missing" ] || fail "dangling link changed"

rm "$scratch/home/.local/bin/bat"
cp "$scratch/bin/batcat" "$scratch/bin/bat"
run_link
[ ! -e "$scratch/home/.local/bin/bat" ] || fail "existing PATH command shadowed"
rm "$scratch/bin/bat"

mv "$scratch/bin/batcat" "$scratch/batcat"
run_link > "$scratch/missing.log" 2>&1
[ ! -L "$scratch/home/.local/bin/bat" ] || fail "created link without source"
grep -q 'Warning:' "$scratch/missing.log" || fail "missing source warning"
mv "$scratch/batcat" "$scratch/bin/batcat"

# A file blocking the directory fails even when tests run as root.
rmdir "$scratch/home/.local/bin"
printf 'blocked\n' > "$scratch/home/.local/bin"
run_link > "$scratch/directory.log" 2>&1
grep -q 'Warning:' "$scratch/directory.log" || fail "directory failure warning"
rm "$scratch/home/.local/bin"
mkdir "$scratch/home/.local/bin"

# Inject a link failure independently of directory creation and permissions.
rm "$scratch/bin/ln"
printf '#!/bin/sh\nexit 1\n' > "$scratch/bin/ln"
chmod +x "$scratch/bin/ln"
run_link > "$scratch/link.log" 2>&1
grep -q 'Warning:' "$scratch/link.log" || fail "link failure warning"
[ ! -L "$scratch/home/.local/bin/bat" ] || fail "unexpected link after failure"

echo "Ubuntu command linking preserves existing commands and tolerates failures."
