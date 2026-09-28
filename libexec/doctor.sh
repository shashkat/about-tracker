#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure,
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# Finds orphaned metadata files in a directory, i.e. .about_<name>.md files whose <name> no longer exists next to
# them. This happens when a file/directory is moved, renamed or deleted by some program other than abt. With -r, the
# subdirectories are searched too.
# Exit status: 0 if no orphans were found, 1 if some were found, 2 if the arguments were invalid. Keeping "orphans
# found" separate from "invalid arguments" lets scripts tell the two apart.

usage() {
    echo "Usage: abt doctor [-r] [directory]"
}

recursive=0
dirs=()
for arg in "$@"; do
    case "$arg" in
        -r) recursive=1 ;;
        -*)
            echo "Error: unknown option '$arg'." >&2
            usage >&2
            exit 2
            ;;
        *) dirs+=("$arg") ;;
    esac
done

if [[ ${#dirs[@]} -gt 1 ]]; then
    echo "Error: too many arguments." >&2
    usage >&2
    exit 2
fi

check_dir="${dirs[0]:-.}" # default to the current directory if no directory is given
check_dir="${check_dir%/}"
[[ -z "$check_dir" ]] && check_dir="/" # the line above turns "/" into an empty string

if [[ ! -d "$check_dir" ]]; then
    echo "Error: '$check_dir' is not a directory." >&2
    exit 2
fi

# Without -r only the given directory itself is searched. find doesn't follow symlinked directories, so a symlink
# loop can't make the recursive search run forever.
depth_args=()
[[ $recursive -eq 0 ]] && depth_args=(-maxdepth 1)

if [[ $recursive -eq 1 ]]; then
    location="$check_dir and its subdirectories"
else
    location="$check_dir"
fi

orphans=()
# -print0 separates the paths with a null character instead of a newline, and read -d '' splits on it, so that file
# names containing spaces or even newlines are read correctly. sort -z sorts them (also null separated) so the output
# order is stable.
while IFS= read -r -d '' item; do
    item_dir="${item%/*}" # the directory the metadata file is in, which is where its entity should be
    entity_name=${item##*/.about_} # same extraction as in ls.sh: remove the longest prefix matching */.about_
    entity_name=${entity_name%.md} # and then the .md suffix

    # -e is true for any existing file/dir. -L additionally catches symlinks whose target is missing, since the
    # symlink itself is still the entity the metadata belongs to.
    if [[ ! -e "${item_dir}/${entity_name}" && ! -L "${item_dir}/${entity_name}" ]]; then
        orphans+=("$item")
    fi
done < <(find "$check_dir" "${depth_args[@]}" -type f -name '.about_*.md' -print0 | sort -z)

if [[ ${#orphans[@]} -eq 0 ]]; then
    printf '%bNo orphaned metadata files found in %s%b\n' "$green" "$location" "$reset"
    exit 0
fi

printf '%b⚠  Found %d orphaned metadata file(s) in %s (the file/directory they describe does not exist):%b\n' \
    "$yellow" "${#orphans[@]}" "$location" "$reset"
for item in "${orphans[@]}"; do
    entity_name=${item##*/.about_}
    entity_name=${entity_name%.md}
    printf '   %b%s%b  (missing: %s)\n' "$yellow" "$item" "$reset" "$entity_name"
done
exit 1
