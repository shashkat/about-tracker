#!/usr/bin/env bash

# ANSI Color Codes
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
grey="\033[90m"
reset="\033[0m"

# Given a path (file or dir), print the name of its metadata file.
# The metadata file lives in the same directory as the target.
function _about_meta_name {
    local target="$1"
    local dir base ext meta_name

    # Resolve to absolute, stripping trailing slash for dirs
    target="${target%/}"

    base="$(basename "$target")"
    if [[ -d "$target" ]]; then
        # corner case: if target is of form some_path/hello/. then instead of echoing .about_dir_..md, echo ../.about_dir_hello.md
        if [[ "$base" == "." ]]; then
            dir="$(dirname "$target")"
            dir="$(realpath "$dir")" # need absolute path because with just target=. dir is also . and then below line would not be able to extract the name of parent dir
            parent_dir="$(basename "$dir")" # this yields just the name of the parent directory of target without any part of path before it which may be present in $dir
            meta_name="../.about_dir_${parent_dir}.md"
        else
            meta_name=".about_dir_${base}.md"
        fi
    else
        # Replace dots with underscores in the full filename (incl. extension)
        # local safe="${base//./_}" # not replacing dots with underscore
        meta_name=".about_file_${base}.md"
    fi

    echo "$meta_name"
}

# Given a path, print the full path to its metadata file (sibling location).
function _about_meta_path {
    local target="$1"
    target="${target%/}"
    local dir meta_name # declare variables dir and meta_name in one line

    dir="$(dirname "$target")" # dirname echos (writes to standard output) the directory part of its rhs (assumes it to be a path). Similar function is basename which returns the file part of its rhs.
    meta_name="$(_about_meta_name "$target")"
    echo "${dir}/${meta_name}" # having braces surrounding the variable makes it more explicit what the variable name is that we want to decode/expand
}

# Print the contents of a metadata file with a label
function _about_print_meta {
    local meta_path="$1"
    local label="$2"
    if [[ -f "$meta_path" ]]; then
        # printf '\033[90m▸ %s: \033[0m' "$label"
        printf '%b▸ %s: %b' "$grey" "$label" "$reset"
        # awk '{printf "\033[90m%s\033[0m\n", $0}' "$meta_path"
        awk "{printf \"${grey}%s${reset}\\n\", \$0}" "$meta_path"
        # echo
    fi
}

# Print the contents of a metadata file with a label (different color for current dir metadata)
function _about_print_meta_currdir {
    local meta_path="$1"
    local label="$2"
    if [[ -f "$meta_path" ]]; then
        # printf '\033[38;5;30m▸ %s: \033[0m' "$label"
        printf '%b▸ %s: %b' "$cyan" "$label" "$reset"
        # awk '{printf "\033[90m%s\033[0m\n", $0}' "$meta_path"
        awk "{printf \"${grey}%s${reset}\\n\", \$0}" "$meta_path"
        # echo
    fi
}
