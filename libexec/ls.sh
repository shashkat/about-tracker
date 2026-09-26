#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# Run the real ls with all arguments
command ls --color "$@" # command is a shell builtin that tells to execute the next words as command rather than 
# as a function or builtin. $@ expands all the arguments to the current function. It expands to $1, $2 etc. 
# as separate quoted words. Using command ensures we use the base ls command and not an alias or function named ls.

# Determine which directory we're listing
list_dir="."
# Find the last non-option (non dash) argument (the directory/file target)
for arg in "$@"; do
    if [[ "$arg" != -* ]]; then # -* matches to any string beginning with -
        list_dir="$arg"
    fi
done
# If it resolves to a file (not a dir), use its parent
if [[ -f "$list_dir" ]]; then
    list_dir="$(dirname "$list_dir")"
fi
# TODO: IF REALPATH GIVES ERROR, WE SHOULD STOP AND NOT PROCEED FURTHUR.
list_dir="$(realpath "$list_dir" 2>/dev/null || echo "$list_dir")" # realpath returns the absolute path of its 
# next word. 2>/dev/null directs the std error to /dev/null (it is a standard way of not printing the error).
# If realpath didn't return 0, then simply keep list_dir as it is. $(to_execute_1 || to_execute_2) is a common
# idiomatic pattern in shell, and is an if-else shorthand for "fallback-on-failure" use cases.

echo
printf "${grey}───────────────about────────────────────${reset}\n"

# 1. Show metadata for the listed dir itself (from one level up)
dir_meta="$(_about_meta_path "$list_dir")"
_about_print_meta_currdir "$dir_meta" "$(basename "$list_dir")/ (this directory)"

# 2. Show metadata for every item inside the listed dir
found_any=0
# Make all globs in this function return empty if no match
shopt -s nullglob
# since above, we ensured that $list_dir is absolute path, all the values that item takes in this loop are also absolute paths
for item in "$list_dir"/.about_*.md; do
    
    entity_name=${item##*/.about_} # here, ## means remove the longest prefix matching whatever pattern is after it. Here, the pattern is */.about_
    entity_name=${entity_name%.md} # % removes the shortest matching suffix from the end

    if [[ -f "${list_dir}/${entity_name}" || -d "${list_dir}/${entity_name}" ]]; then
        _about_print_meta "$item" "$entity_name"
    fi
done
shopt -u nullglob
