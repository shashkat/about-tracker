#!/usr/bin/env bash

# get location of current script
# first check if BASH_SOURCE variable is empty or not. It is empty if current script was called using source. 
# If current script was called using ./ then it holds the location to current script
if [[ -n $BASH_SOURCE ]]; then
    current_script_loc="${BASH_SOURCE[0]}"
else
    current_script_loc="${0}"
fi

# Import our library
source "$(dirname "${current_script_loc}")/lib/functions.sh"

function about_create {
    # $# is a special bash variable to indicate the number of arguments provided to the function. -eq indicates
    # numerical comparison between left and right entities. Note that variables in bash are inherently typeless, 
    # and their type is interpreted according to context. Here, if -eq were replaced by == then there would have 
    # been a string comparison and in this case, the result would still be the same
    if [[ $# -eq 0 ]]; then
        echo "Usage: about_create <file_or_directory>"
        return 1
    fi

    # local declares a local context variable and not global variable. $1 is the first argument, and surrounding 
    # it with quotes avoids problems in cases where $1 may be something like 'my dir', and be split into two 
    # entities if quotes were not around $1 here.
    local target="$1"
    target="${target%/}" # target%pattern leads to removal of shortest suffix matching pattern from target. % is a 
    # pattern-removal modifier in bash that is designed to work only on variables and not directly string inputs. 
    # Hence, it doesnt assume here that target is a string itself, but a variable storing some string value.

    # ! is "not" as in other languages. -e checks if its rhs is an existing path or not.
    if [[ ! -e "$target" ]]; then
        echo "Error: '$target' does not exist."
        return 1
    fi

    local meta_path="$(_about_meta_path "$target")" # get the path of the metadata file associated with target.

    if [[ -f "$meta_path" ]]; then # -f checks if meta_path exists, and is a regular file and not a directory/symlink etc.
        echo "Metadata file already exists: $meta_path"
    else
        # Create with a starter template
        { # { ... } is a command group. whatever is inside braces, acts as a single compound command.
            echo ""
        } > "$meta_path"
        echo "Created: $meta_path"
    fi

    # Open in vim (or $EDITOR if set)
    "${EDITOR:-vim}" "$meta_path" # ${VAR:-word} is a standard parameter expansion in bash, that gives word if VAR is unset or empty, else VAR
}

function ls {
    # Run the real ls with all arguments
    command ls --color "$@" # command is a shell builtin that tells to execute the next words as command rather than 
    # as a function or builtin. $@ expands all the arguments to the current function. It expands to $1, $2 etc. 
    # as separate quoted words.

    # Determine which directory we're listing
    local list_dir="."
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
    # printf "\033[1;34m%s\033[0m\n" "── .about metadata ─────────────────────────────────"
    printf "\033[90m%s\033[0m\n" "───────────────about────────────────────"

    # 1. Show metadata for the listed dir itself (from one level up)
    local dir_meta
    dir_meta="$(_about_meta_path "$list_dir")"
    _about_print_meta_currdir "$dir_meta" "$(basename "$list_dir")/ (this directory)"

    # 2. Show metadata for every item inside the listed dir
    local found_any=0
    # Make all globs in this function return empty if no match
    if [ -n "$ZSH_VERSION" ]; then # -n checks for non-zero length. -e checks the existence of files, whereas -n helps for strings
        # Zsh specific setting
        setopt local_options null_glob
    elif [ -n "$BASH_VERSION" ]; then
        # Bash specific setting
        shopt -s nullglob
    fi
    # since above, we ensured that $list_dir is absolute path, all the values that item takes in this loop are also absolute paths
    for item in "$list_dir"/.[!.]* "$list_dir"/*; do # "$list_dir"/.[!.]* matches all entries in current directory, whose names start with . but excludes just . and .. 
        # "$list_dir"/* expands to all nonhidden files. * by default doesn't include the names starting with .

        # Skip the metadata files themselves, and non-existent globs
        [[ -e "$item" ]] || continue # ignore non existent path
        local bname="$(basename "$item")"
        [[ "$bname" == .about_file_* || "$bname" == .about_dir_* ]] && continue # here, the usage of || is inside [[...]] hence 
        # it means the logical OR. && here holds commands to its left and right, and executes the right one only if the 
        # left one executes successfully (exit status 0).

        local meta="$(_about_meta_path "$item")"
        if [[ -f "$meta" ]]; then
            _about_print_meta "$meta" "$bname"
            found_any=1
        fi
    done

    if [ -n "$BASH_VERSION" ]; then
        # Bash specific setting
        shopt -u nullglob
    fi
}

function mv {
    # Collect all source arguments (everything except the last, which is dest)
    local args=("$@")

    # to keep uniformity with copy command, keeping the move command of the actual files before the metadata files
    command mv "$@" || return $? 

    local dest="${args[-1]}"
    unset 'args[-1]' # this removes the last entity from args array. Also, its not that now args[-1] points to the 
    # original second last entity of it. args[-1] now points to nothing. The original second last entity of args is 
    # still accessed by args[-2]
    local sources=("${args[@]}") # doing something like list[@] is a shorthand for looping through all the elements. Here, for cleanliness purposes, having a separate array storing all the non-last arguments.

    # Move each source's metadata file alongside it
    for src in "${sources[@]}"; do # The default behaviour in bash (not zsh) if only $sources were used in loop was to iterate only through the first entity in sources. sources[@] is a shorthand to counter that.
        [[ "$src" == -* ]] && continue   # skip flags
        local src_meta="$(_about_meta_path "$src")"
        if [[ -f "$src_meta" ]]; then
            # Determine where the meta file should land after the move
            # local dest_dir dest_meta_name dest_meta_path
            if [[ -d "$dest" ]]; then
                # Moving into a directory — keep the same metadata filename
                local dest_dir="$dest"
                local dest_meta_name="$(_about_meta_name "$src")"
            else
                # Renaming — derive metadata filename from the new name
                local dest_dir="$(dirname "$dest")"
                local dest_meta_name="$(_about_meta_name "$dest")"
            fi
            local dest_meta_path="${dest_dir}/${dest_meta_name}"
            command mv "$src_meta" "$dest_meta_path"
        fi
    done
}

function cp {
    # this function has code very similar to in mv function above. For comments, see in mv function hence.
    local args=("$@")

    # it is important that first, the actual file's copy is attempted and then of the metadata files. This way, 
    # if there is to be an error in the original copy command (like when we attempt to copy a dir without using -r), 
    # it happens before any of the metadata files are copied
    command cp "$@" || return $? # $? holds the exit status of the last command that ran. Hence, here we exit and return the exit status of the last command.

    local dest="${args[-1]}"
    unset 'args[-1]'
    local sources=("${args[@]}")

    for src in "${sources[@]}"; do
        [[ "$src" == -* ]] && continue
        local src_meta="$(_about_meta_path "$src")"
        if [[ -f "$src_meta" ]]; then
            
            if [[ -d "$dest" ]]; then
                # Copying into a directory — keep the same metadata filename
                local dest_dir="$dest"
                local dest_meta_name="$(_about_meta_name "$src")"
            else
                # Renaming while copying — derive metadata filename from the new name
                local dest_dir="$(dirname "$dest")"
                local dest_meta_name="$(_about_meta_name "$dest")"
            fi
            local dest_meta_path="${dest_dir}/${dest_meta_name}"
            command cp "$src_meta" "$dest_meta_path"
        fi
    done
}

function rm {
    # Collect targets (non-flag args) and find associated metadata files
    local targets=()
    local flags=()
    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            flags+=("$arg") # in bash, if we would have done simply flags+=$arg here, then the value of arg would 
            # have been appended to the first entry in flags. Hence, we need parenthesis to actually add an entry to flags.
        else
            targets+=("$arg")
        fi
    done

    local meta_files=()
    for target in "${targets[@]}"; do
        local meta="$(_about_meta_path "$target")"
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
            return 1
        fi
        # Delete metadata files first
        for m in "${meta_files[@]}"; do
            command rm "${flags[@]}" "$m"
        done
    fi

    command rm "$@"
}