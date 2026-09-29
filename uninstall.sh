#!/usr/bin/env bash

# Undoes what install.sh did:
#   1. removes the about-tracker block from ~/.zshrc and ~/.bashrc, and
#   2. deletes the installed copy in ~/.local/share/about-tracker.
# The .about_<name>.md metadata files you created are not touched, since they are your data and not part of the
# installation. ~/.local/share and the shell init files themselves are also kept, as other programs use them too.

set -e # make the shell exit when any command below fails

INSTALL_DIR="$HOME/.local/share/about-tracker" # same location install.sh copies the package to
BLOCK_START="# >>> about-tracker >>>"
BLOCK_END="# <<< about-tracker <<<"

# Removes the about-tracker block from the shell init file $1, if it has one.
remove_block() {
    local file="$1"
    [ -f "$file" ] || return 0
    grep -qF "$BLOCK_START" "$file" || return 0

    # Without the end marker, the awk below would drop everything after the start marker, so leave such a file alone.
    if ! grep -qF "$BLOCK_END" "$file"; then
        echo "Warning: $file has '$BLOCK_START' but no '$BLOCK_END'. Please remove the about-tracker lines by hand." >&2
        return 0
    fi

    # Same awk as in install.sh: print every line except the ones from BLOCK_START to BLOCK_END (inclusive).
    local content
    content="$(awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
        index($0, start) { skip=1; next }
        index($0, end) { skip=0; next }
        !skip { print }
    ' "$file")"

    # Writing with > (instead of mv-ing a temporary file over it) keeps the file itself, so a .zshrc that is a
    # symlink (e.g. into a dotfiles repo) stays a symlink and keeps its permissions. $(...) drops trailing newlines,
    # so one is added back, unless nothing is left.
    if [ -n "$content" ]; then
        printf '%s\n' "$content" > "$file"
    else
        : > "$file" # : is a command that does nothing, so this just empties the file
    fi
    echo "Removed the about-tracker block from $file"

    # Aliases like `alias ls='abt ls'` (see the README) are outside the block, and would break once abt is gone.
    # The pattern matches "abt" as a whole word on lines that are not comments.
    local leftover
    leftover="$(grep -nE '^[^#]*(^|[^[:alnum:]_])abt([^[:alnum:]_]|$)' "$file" || true)"
    if [ -n "$leftover" ]; then
        echo "Warning: these lines in $file still use abt, which will no longer exist. Please remove them:" >&2
        printf '%s\n' "$leftover" | sed 's/^/   line /' >&2
    fi
}

# Everything runs inside main, which is only called on the last line. Bash reads a script bit by bit while running
# it, so if this script is run from inside INSTALL_DIR, deleting that directory midway could otherwise cut it off.
# Having the whole function read before it runs avoids that.
main() {
    remove_block "$HOME/.zshrc"
    remove_block "$HOME/.bashrc" # both, in case the user switched shells after installing

    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "Deleted $INSTALL_DIR"
    fi

    echo "about-tracker uninstalled."
    echo "Your .about_<name>.md metadata files were not touched. Open a new terminal to finish removing abt from your"
    echo "shell (the current session still has it on its PATH)."
}

main
