#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

# $# is a special bash variable to indicate the number of arguments provided to the function. -eq indicates
# numerical comparison between left and right entities. Note that variables in bash are inherently typeless, 
# and their type is interpreted according to context. Here, if -eq were replaced by == then there would have 
# been a string comparison and in this case, the result would still be the same
if [[ $# -eq 0 ]]; then
    echo "Error: No argument supplied!"
    echo "Usage: about_create <file_or_directory>"
    exit 1 # return 1 is different from exit 1 in the sense that return is used inside functions and returns 1 to the function's caller instead of exiting the entire script, which exit 1 does.
fi

# $1 is the first argument, and surrounding it with quotes avoids problems in cases where $1 may be something 
# like 'my dir', and be split into two entities if quotes were not around $1 here.
target="$1"
target="${target%/}" # target%pattern leads to removal of shortest suffix matching pattern from target. % is a 
# pattern-removal modifier in bash that is designed to work only on variables and not directly string inputs. 
# Hence, it doesnt assume here that target is a string itself, but a variable storing some string value.

# ! is "not" as in other languages. -e checks if its rhs is an existing path or not.
if [[ ! -e "$target" ]]; then
    echo "Error: '$target' does not exist."
    exit 1 
fi

meta_path="$(_about_meta_path "$target")" # get the path of the metadata file associated with target.

if [[ -f "$meta_path" ]]; then # -f checks if meta_path exists, and is a regular file and not a directory/symlink etc.
    echo "Opening already existing file $meta_path for editing."
else
    # Create with a starter template
    { # { ... } is a command group. whatever is inside braces, acts as a single compound command.
        echo ""
    } > "$meta_path"
    echo "Created: $meta_path"
fi

# Open in vim (or $EDITOR if set)
"${EDITOR:-vim}" "$meta_path" # ${VAR:-word} is a standard parameter expansion in bash, that gives word if VAR is unset or empty, else VAR


# corner cases- 
# - dot case (present directory about create)
# - when no file supplied
# - when non exisitig file supplied
# - when already existing file supplied