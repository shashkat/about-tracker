#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# Collect all source arguments (everything except the last, which is dest)
args=("$@")

# in bash: get last element as destination, then reconstruct sources without it
dest="${args[${#args[@]}-1]}"
unset "args[${#args[@]}-1]" # this removes the last entity from args array. Also, its not that now args[-1] points to the 
# original second last entity of it. args[-1] now points to nothing. The original second last entity of args is 
# still accessed by args[-2]
sources=("${args[@]}") # doing something like list[@] is a shorthand for looping through all the elements. Here, for cleanliness purposes, having a separate array storing all the non-last arguments.

# Move each source's metadata file alongside it
for src in "${sources[@]}"; do # The default behaviour in bash (not zsh) if only $sources were used in loop was to iterate only through the first entity in sources. sources[@] is a shorthand to counter that.
    [[ "$src" == -* ]] && continue   # skip flags
    src_meta="$(_about_meta_path "$src")"

    if [[ -f "$src_meta" ]]; then
        # Determine where the meta file should land after the move
        if [[ -d "$dest" ]]; then
            # Moving into a directory — keep the same metadata filename
            dest_dir="$dest"
            dest_meta_name="$(_about_meta_name "$src")"
        else
            # Renaming — derive metadata filename from the new name
            dest_dir="$(dirname "$dest")"
            dest_meta_name="$(_about_meta_name "$dest")"
        fi

        dest_meta_path="${dest_dir}/${dest_meta_name}"
    fi
done

# it is important to do the actual move after the metadata move params has been computed because for directories, 
# if we move the actual directory first, then it is detected that the target location is a directory that 
# exists meaning that we are not renaming but moving into a directory. Hence, the move doesn't happen correctly.
command mv "$@" || exit $?

# computed all params related to metadata moving before, but just moving it after the actual files
command mv "$src_meta" "$dest_meta_path"
