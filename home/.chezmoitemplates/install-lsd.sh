install_lsd() (
    set -e
    export PATH="$HOME/.local/bin:$PATH"
    if command -v lsd >/dev/null 2>&1 && [ -x "$(command -v lsd)" ]; then
        echo 'Already installed lsd'
        exit 0
    fi
    destination="$HOME/.local/bin/lsd"
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        echo "Conflicting destination: $destination. Move it explicitly before retrying." >&2
        exit 1
    fi
    policy="$(LC_ALL=C apt-cache policy lsd)" || exit $?
    candidate="$(printf '%s\n' "$policy" | awk '/Candidate:/ {print $2; exit}')"
    if [ -n "$candidate" ] && [ "$candidate" != '(none)' ]; then
        # An APT failure is not evidence that there is no package candidate.
        sudo apt-get install -y lsd || exit $?
        lsd --version || exit $?
        exit 0
    fi

    # Published SHA-256 digests from the v1.2.0 release assets:
    # https://github.com/lsd-rs/lsd/releases/expanded_assets/v1.2.0
    version=v1.2.0
    case "$(uname -m)" in
        x86_64|amd64)
            target=x86_64-unknown-linux-musl
            checksum=77849da1210336534258551a581401ba19ae6b8d7b66a2a1feff148ad41e3814
            ;;
        aarch64|arm64)
            target=aarch64-unknown-linux-musl
            checksum=642ecb1a763b9f790a99c83a1445c117a6813ed4edb5d498d4420423c6353eb8
            ;;
        *) echo 'No lsd fallback for this architecture.' >&2; exit 1 ;;
    esac
    asset="lsd-$version-$target"
    staging="$(mktemp -d)" || exit $?
    trap 'rm -rf "$staging"' EXIT
    curl -fsSL "https://github.com/lsd-rs/lsd/releases/download/$version/$asset.tar.gz" -o "$staging/archive.tar.gz" || exit $?
    printf '%s  %s\n' "$checksum" "$staging/archive.tar.gz" | sha256sum -c - || exit $?
    tar -xzf "$staging/archive.tar.gz" -C "$staging" "$asset/lsd" || exit $?
    chmod 755 "$staging/$asset/lsd" || exit $?
    "$staging/$asset/lsd" --version || exit $?
    mkdir -p "$HOME/.local/bin" || exit $?
    # Stage on the destination filesystem and publish without overwriting a
    # destination created concurrently. Hard-link creation fails on conflicts.
    staged_binary="$(mktemp "$HOME/.local/bin/.lsd.XXXXXXXX")" || exit $?
    trap 'rm -rf "$staging"; rm -f "$staged_binary"' EXIT
    cp "$staging/$asset/lsd" "$staged_binary" || exit $?
    chmod 755 "$staged_binary" || exit $?
    ln "$staged_binary" "$destination" || exit $?
    "$destination" --version
)
# This optional tool must not prevent the rest of setup from completing.
lsd_status=0
install_lsd || lsd_status=$?
if [ "$lsd_status" -ne 0 ]; then
    echo 'Warning: lsd installation failed. Retaining ordinary ls. Check the error above, resolve package/network or file conflicts, and retry the core installer (see README).' >&2
fi
