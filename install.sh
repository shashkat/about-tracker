#!/usr/bin/env bash

set -e

# Determine the source directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the stable install directory
INSTALL_DIR="$HOME/.local/share/about-tracker"

# Copy the package into a stable install directory (~/.local/share/about-tracker)
mkdir -p "$HOME/.local/share"
if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    cp -R "$SCRIPT_DIR" "$INSTALL_DIR"
fi
chmod +x "$INSTALL_DIR/bin/"* 2>/dev/null || true
chmod +x "$INSTALL_DIR/install.sh" 2>/dev/null || true

# Detect if the shell being used is Bash or zsh
if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == *"zsh"* ]]; then
    activation_file="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [[ "$SHELL" == *"bash"* ]]; then
    activation_file="$HOME/.bashrc"
else
    if [ -f "$HOME/.zshrc" ]; then
        activation_file="$HOME/.zshrc"
    else
        activation_file="$HOME/.bashrc"
    fi
fi

# Ensure activation_file exists
touch "$activation_file"

# Add a marked block to the user's shell init file (.bashrc or .zshrc)
BLOCK_START="# >>> about-tracker >>>"
BLOCK_END="# <<< about-tracker <<<"

if grep -qF "$BLOCK_START" "$activation_file" 2>/dev/null; then
    tmp_file="$(mktemp)"
    awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
        index($0, start) { skip=1; next }
        index($0, end) { skip=0; next }
        !skip { print }
    ' "$activation_file" > "$tmp_file"
    mv "$tmp_file" "$activation_file"
fi

if [ -s "$activation_file" ] && [ -n "$(tail -c 1 "$activation_file")" ]; then
    echo "" >> "$activation_file"
fi

cat << 'EOF' >> "$activation_file"
# >>> about-tracker >>>
export ABOUT_TRACKER_PATH="$HOME/.local/share/about-tracker"
source "$ABOUT_TRACKER_PATH/shell/about-tracker.sh"
# <<< about-tracker <<<
EOF

# Print that user should source the activation file to make changes take effect in current process
echo "about-tracker installed successfully!"
echo "Please run the following command to make the changes take effect in your current shell session:"
echo "source $activation_file"
