#!/usr/bin/env bash

set -e # make the shell exit when any command below fails

# Determine the source directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # BASH_SOURCE[0] holds the name install.sh when ./install.sh is run. $() runs the command inside 
# parenthesis in a subshell, captures the stdout of that command and replaces the $() expression with that output. dirname just returns the name of the parent 
# directory name (not full path) of its argument. Finally, SCRIPT_DIR holds the full path to the directory where this file (install.sh) is stored.

# Define the stable install directory
INSTALL_DIR="$HOME/.local/share/about-tracker" # putting in share as it seems the most reasonable place out of other directories in .local

###############
### Copy the package into a stable install directory (~/.local/share/about-tracker)
###############
mkdir -p "$HOME/.local/share"
if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    cp -R "$SCRIPT_DIR" "$INSTALL_DIR"
fi

# try to make all the files in bin and libexec executable, but if something fails (which could be because of many reasons like the file being non standard type), dont emit
# false as that would lead to the whole script exiting (because of set -e at top)
chmod +x "$INSTALL_DIR/bin/"* "$INSTALL_DIR/libexec/"* 2>/dev/null || true

###############
### Detect if the shell being used is Bash or zsh
###############
if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == *"zsh"* ]]; then # -n detects non empty
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

###############
### Add a marked block to the user's shell init file (.bashrc or .zshrc)
###############
BLOCK_START="# >>> about-tracker >>>"
BLOCK_END="# <<< about-tracker <<<"

# -q makes grep not print output and -F indicates that the pattern is not regex but literal.
if grep -qF "$BLOCK_START" "$activation_file" 2>/dev/null; then
    tmp_file="$(mktemp)" # create a temporary file and store its location in tmp_file
    # This is the start of an awk block, which is a small code in itself. -v in the first line means that assign a particular value to a variable named 
    # something. So the value of $BLOCK_START is assigned to the variable start. The awk code goes line-by-line through the input file, which is $activation_file 
    # here. Inside the awk code, each like is an if statement. For each line, the first part is a rule and second part is an action to do if that rule is 
    # true. Eg- if index($0, start) is true, then do { skip=1; next }. index($0, start) checks if start is present in current line. { skip=1; next } makes the 
    # value of variable skip as 1, and moves to the next iteration.
    # Basically this leads to the contents of activation_file being compied to tmp_file, except the inclusive block between $BLOCK_START and $BLOCK_END.
    awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
        index($0, start) { skip=1; next }
        index($0, end) { skip=0; next }
        !skip { print }
    ' "$activation_file" > "$tmp_file"
    mv "$tmp_file" "$activation_file"
fi

# -n just looks at the supplied string (and not a file by its name) and returns true if the supplied string is non-empty. It gives false for newline.
# -f is true when something is a file and exists
# -s is true when some file/dir exists and has size greater than 0
# This checks if activation_file is non-empty and ends without a newline. If that is the case, it adds a newline
if [ -s "$activation_file" ] && [ -n "$(tail -c 1 "$activation_file")" ]; then
    echo "" >> "$activation_file" # this appends a newline to the file.
fi

# Following is a standard way to print/add multiple lines of text at once instead of using multiple echo statements
# ```
# cat << EOF
# some multiline text
# multiline text part 2
# EOF
# ```
# >> allows to redirect the output to a file instead of printing it
# the quotes around EOF make the text literal and the $HOME etc dont get expanded before getting inserted into activation_file
cat << 'EOF' >> "$activation_file"
# >>> about-tracker >>>
export ABOUT_TRACKER_PATH="$HOME/.local/share/about-tracker"
export PATH="$ABOUT_TRACKER_PATH/bin:$PATH"
# <<< about-tracker <<<
EOF

###############
### Print that user should source the activation file to make changes take effect in current process
###############
echo "about-tracker installed successfully!"
echo "Please run the following command to make the changes take effect in your current shell session:"
echo "source $activation_file"
