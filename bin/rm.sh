#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi
source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# Collect targets (non-flag args) and find associated metadata files
targets=()
flags=()
for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
        flags+=("$arg") # in bash, if we would have done simply flags+=$arg here, then the value of arg would 
        # have been appended to the first entry in flags. Hence, we need parenthesis to actually add an entry to flags.
    else
        targets+=("$arg")
    fi
done

meta_files=()
for target in "${targets[@]}"; do
    meta="$(_about_meta_path "$target")"
    [[ -f "$meta" ]] && meta_files+=("$meta")
done

if [[ ${#meta_files[@]} -gt 0 ]]; then # '#' symbol before any array object indicates length of it. If the object is a simple string, then '#' returns the number of characters in the string
    echo
    printf '\033[1;33m⚠  rm: the following metadata files will also be deleted:\033[0m\n'
    for m in "${meta_files[@]}"; do
        printf '   \033[0;33m%s\033[0m\n' "$m"
    done
    printf '\033[1;33mProceed? [y/N] \033[0m'
    read -r answer
    if [[ "$answer" != [Yy] ]]; then
        echo "Aborted."
        exit 1
    fi
    # Delete metadata files first
    for m in "${meta_files[@]}"; do
        command rm "${flags[@]}" "$m"
    done
fi

command rm "$@"