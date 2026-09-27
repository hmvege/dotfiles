# Ubuntu may expose packaged tools as batcat and fdfind.
link_ubuntu_command() {
    local source_command="$1" destination="$HOME/.local/bin/$2" source_path
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        echo "Keeping existing $destination"
    elif command -v "$2" >/dev/null 2>&1; then
        echo "Keeping existing $2 command"
    elif source_path="$(command -v "$source_command")"; then
        if ! mkdir -p "$HOME/.local/bin" || ! ln -s "$source_path" "$destination"; then
            echo "Warning: could not create $destination. Keeping existing commands." >&2
        fi
    else
        echo "Warning: $source_command is unavailable. Skipping $destination." >&2
    fi
}
