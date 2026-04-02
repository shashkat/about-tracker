#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# this function has code very similar to in mv script. For comments, see in mv script hence.
args=("$@")

# in bash: get last element as destination, then reconstruct sources without it
dest="${args[${#args[@]}-1]}"
unset "args[${#args[@]}-1]"
sources=("${args[@]}")

for src in "${sources[@]}"; do
    [[ "$src" == -* ]] && continue
    src_meta="$(_about_meta_path "$src")"
    if [[ -f "$src_meta" ]]; then
        
        if [[ -d "$dest" ]]; then
            # Copying into a directory — keep the same metadata filename
            dest_dir="$dest"
            dest_meta_name="$(_about_meta_name "$src")"
        else
            # Renaming while copying — derive metadata filename from the new name
            dest_dir="$(dirname "$dest")"
            dest_meta_name="$(_about_meta_name "$dest")"
        fi
        dest_meta_path="${dest_dir}/${dest_meta_name}"
    fi
done

# it is important that first, the actual file's copy is attempted and then of the metadata files. This way, 
# if there is to be an error in the original copy command (like when we attempt to copy a dir without using -r), 
# it happens before any of the metadata files are copied
command cp "$@" || exit $? # $? holds the exit status of the last command that ran. Hence, here we exit and echo the exit status of the last command.

# computed all params related to metadata copying before, but just copying it after the actual files. The problem 
# with copying metadata before actual files is that if its directory that is being copied, then it will be 
# detected that the target location is existing and not that we are just renaming and copying
command cp "$src_meta" "$dest_meta_path"
