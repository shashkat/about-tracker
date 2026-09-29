# Records docs/demo.gif, the about-tracker demo shown in the README.
#
# Run it from the repo root, since VHS writes the Output path relative to the directory it is run from:
#   vhs docs/demo.tape
#
# VHS starts its shell without reading ~/.bashrc or ~/.zshrc, but with the PATH of the terminal it was run from. So
# depending on that terminal, abt is either missing or the installed copy. The hidden section below makes abt always
# the copy in this repo, and builds a throwaway demo directory to record in. Commands between Hide and Show run in
# the shell, but are not part of the GIF.

Output docs/demo.gif

Require bash
Require git
Require vim

Set Shell "bash"
Set FontSize 22
Set Width 1200
Set Height 650
Set Padding 30
Set TypingSpeed 60ms
Set Theme "Catppuccin Mocha"

Hide
# Use abt from this repo, a plain prompt, vim as the editor, and the tab completion for abt. The repo root is found
# with git, so this works no matter which directory inside the repo VHS was run from.
Type `repo="$(git rev-parse --show-toplevel)"` Enter
Type `export ABOUT_TRACKER_PATH="$repo" PATH="$repo/bin:$PATH" EDITOR=vim PS1='\[\e[1;36m\]project\[\e[0m\] $ '` Enter
Type `source "$repo/completions/abt.sh"` Enter
Type `alias ls='abt ls'` Enter
Type `alias cp='abt cp'` Enter
Type `alias mv='abt mv'` Enter
Type `alias rm='abt rm'` Enter
# A small project with a few files and descriptions, in a temporary directory
Type `demo="$(mktemp -d)" && mkdir -p "$demo/project/archive" "$demo/project/experiment_2" "$demo/project/experiment_3" && touch "$demo/project/results.csv"` Enter
Type `echo "Effect of learning rate on model accuracy" > "$demo/.about_project.md"` Enter
Type `echo "same as experiment_2 but with a new seed. Broken, don't use" > "$demo/project/.about_experiment_3.md"` Enter
Type `echo "results that are no longer used, kept for reference" > "$demo/project/.about_archive.md"` Enter
Type `cd "$demo/project" && clear` Enter
Sleep 500ms
Show

# 1. abt ls: the normal ls output, followed by the descriptions
Type "ls" Sleep 500ms Enter
Sleep 3s

# 2. Describe a file. Tab completes "abt mo" to "abt modify", then vim opens the description file.
Type "abt mo" Sleep 400ms Tab Sleep 400ms
Type "results.csv" Sleep 500ms Enter
Sleep 1.5s
Type "i"
Type "final results (lr=0.001). Use this one for the paper"
Sleep 800ms
Escape
Type ":wq" Sleep 400ms Enter
Sleep 1s

# 3. The new description shows up in abt ls
Type "clear" Sleep 500ms Enter Sleep 500ms
Type "ls" Sleep 500ms Enter
Sleep 3s

# 4. Moving the file with abt mv takes its description along
Type "mv results.csv archive/" Sleep 500ms Enter
Sleep 1s
Type "ls archive" Sleep 500ms Enter
Sleep 4s

# Clean up the demo directory (not recorded)
Hide
Type `cd / && rm -rf "$demo"` Enter
