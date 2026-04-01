#!/usr/bin/env bash
# set -euo pipefail # set command sets the options for the shell. -e causes the script to exit immediately if any 
# command returns a non-zero exit status. -u leads to references to empty variables as errors, instead of 
# imagining them as empty strings instead. -o allows having a named command set, hence -o pipefail go together. 
# -o pipefail makes command pipelines to fail if any command in the pipeline fails, instead of just the last one.

set -uo pipefail # removing the -e part because I still want to run all tests even if some fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # current script's directory, post resolving symlinks
# Import functions
# source "${SCRIPT_DIR}/../lib/functions.sh"
source "${SCRIPT_DIR}/../main.sh"

declare -i tests_run=0 # declare forces the variable to be treated as an integer and allows operations like ((tests_run++))

say() {
    printf "%b\n" "$@" # %b is a version of %s that expands backslash escape sequences. This was required to print color. that %s is a placeholder for a string value. printf "%s\n" executes again and again until all the entities are exhausted in $@
}

is() {
    tests_run=$((tests_run + 1))
    local got="$1"
    local expected="$2"
    local msg="$3"

    if [[ "$got" == "$expected" ]]; then
        # Green status, Grey message
        say "${green}ok $tests_run${reset} - ${grey}${msg}${reset}"
    else
        # Red status, Grey message
        say "${red}not ok $tests_run${reset} - ${grey}${msg}${reset}"
        say "#   got:   $got"
        say "#   want:  $expected"
        # exit 1 # not exiting if there was an error, because want to test all cases even if some failed before
    fi
}

test_about_meta_name() {
    local got
    local base_dir="${SCRIPT_DIR}/test_folders"

    # 1. Standard File
    # Current behavior: appends .about_file_ prefix and .md suffix
    got="$(_about_meta_name "$base_dir/abc.md")"
    is "$got" ".about_file_abc.md.md" "File: abc.md"

    # 2. Standard Directory
    # Ensure it uses .about_dir_ prefix
    # Note: We simulate a directory path; the function uses [[ -d ]] 
    # so these paths should actually exist in your test environment.
    got="$(_about_meta_name "$base_dir/my_folder")"
    is "$got" ".about_dir_my_folder.md" "Directory: my_folder"

    # 3. Directory with Trailing Slash
    # Testing the target="${target%/}" logic
    got="$(_about_meta_name "$base_dir/my_folder/")"
    is "$got" ".about_dir_my_folder.md" "Directory: my_folder/ (trailing slash)"

    # 4. Corner Case: The Dot (.) target
    # Testing the if [[ "$base" == "." ]] logic
    # This requires realpath, so we use a subshell to cd in
    (
        cd "$base_dir/my_folder" || exit
        got="$(_about_meta_name ".")"
        is "$got" "../.about_dir_my_folder.md" "Corner case: dot (.) path"
    )
    tests_run=$((tests_run + 1)) # wherever I am spinning up a subshell, the increment in tests_run in the 
    # subshell doesn't reflect in this script. Hence I have to do that manually in those cases.

    # 5. Hidden File
    # Testing how it handles files that already start with a dot
    got="$(_about_meta_name "$base_dir/.hidden")"
    is "$got" ".about_file_.hidden.md" "File: hidden file .hidden"

    # 6. Deeply nested file
    got="$(_about_meta_name "$base_dir/a/b/c/leaf.txt")"
    is "$got" ".about_file_leaf.txt.md" "File: Deeply nested leaf.txt"

    # 7. Basic Relative File Path
    (
        cd "$base_dir" || exit
        # Passing a relative filename in the current directory
        got="$(_about_meta_name "abc.md")"
        is "$got" ".about_file_abc.md.md" "Relative path: simple file"
    )
    tests_run=$((tests_run + 1))

    # 8. Relative Path to a nested file
    (
        cd "$base_dir" || exit
        # Moving down into the tree
        got="$(_about_meta_name "ghi/jkl.md")"
        is "$got" ".about_file_jkl.md.md" "Relative path: nested file ghi/jkl.md"
    )
    tests_run=$((tests_run + 1))

    # 9. Relative Path using '..' (Parent directory)
    (
        cd "$base_dir/ghi" || exit
        # Target is abc.md which is one level up
        got="$(_about_meta_name "../abc.md")"
        is "$got" ".about_file_abc.md.md" "Relative path: using .."
    )
    tests_run=$((tests_run + 1))

    # 10. The Dot (.) corner case from a nested folder
    (
        cd "$base_dir/a/b/c" || exit
        # This triggers your logic: meta_name="../.about_dir_${parent_dir}.md"
        got="$(_about_meta_name ".")"
        is "$got" "../.about_dir_c.md" "Relative path: dot (.) in nested folder 'c'"
    )
    tests_run=$((tests_run + 1))

    # 11. Relative Directory Path
    (
        cd "$base_dir" || exit
        got="$(_about_meta_name "ghi")"
        is "$got" ".about_dir_ghi.md" "Relative path: directory 'ghi'"
    )
    tests_run=$((tests_run + 1))

    # 12. The "Dot-Slash" prefix (./)
    (
        cd "$base_dir" || exit
        got="$(_about_meta_name "./def.md")"
        is "$got" ".about_file_def.md.md" "Relative path: using ./"
    )
    tests_run=$((tests_run + 1))

    say "${yellow}Testing complete for function _about_meta_name()!${reset}"
}

test_about_meta_path() {
    local got
    local base_dir="${SCRIPT_DIR}/test_folders"
    
    # 1. Absolute Path to a Directory
    # Target: .../test_folders/ghi
    # Expected: .../test_folders/.about_dir_ghi.md
    got="$(_about_meta_path "$base_dir/ghi")"
    is "$got" "$base_dir/.about_dir_ghi.md" "Abs Path Dir: ghi"

    # 2. Absolute Path to a File
    # Target: .../test_folders/abc.md
    # Expected: .../test_folders/.about_file_abc.md.md
    got="$(_about_meta_path "$base_dir/abc.md")"
    is "$got" "$base_dir/.about_file_abc.md.md" "Abs Path File: abc.md"

    # 3. Relative Path from Current Directory
    # Target: abc.md
    # Expected: ./.about_file_abc.md.md (dirname of "abc.md" is ".")
    (
        cd "$base_dir" || exit
        got="$(_about_meta_path "abc.md")"
        is "$got" "./.about_file_abc.md.md" "Rel Path: simple file"
    )
    tests_run=$((tests_run + 1))

    # 4. Relative Path to Nested File
    # Target: ghi/mno.md
    # Expected: ghi/.about_file_mno.md.md
    (
        cd "$base_dir" || exit
        got="$(_about_meta_path "ghi/mno.md")"
        is "$got" "ghi/.about_file_mno.md.md" "Rel Path: nested file ghi/mno.md"
    )
    tests_run=$((tests_run + 1))

    # 5. Corner Case: The Dot (.) target
    # Target: .
    # Your _about_meta_name returns "../.about_dir_my_folder.md"
    # dirname "." returns "."
    # Expected Result: ./../.about_dir_my_folder.md
    (
        cd "$base_dir/my_folder" || exit
        got="$(_about_meta_path ".")"
        is "$got" "./../.about_dir_my_folder.md" "Rel Path Corner Case: dot (.)"
    )
    tests_run=$((tests_run + 1))

    # 6. Deeply Nested Absolute Path
    # Target: .../test_folders/a/b/c
    # Expected: .../test_folders/a/b/.about_dir_c.md
    got="$(_about_meta_path "$base_dir/a/b/c")"
    is "$got" "$base_dir/a/b/.about_dir_c.md" "Abs Path: deeply nested directory"

    say "${yellow}Testing complete for function _about_meta_path()!${reset}"
}

test_about_print_meta() {
    local got
    local base_dir="${SCRIPT_DIR}/test_folders"
    
    # 1. Single Line
    got="$(_about_print_meta "$base_dir/.about_file_def.md.md" "File Note")"
    
    # We build the expected string using those literal variables
    printf -v expected '%b▸ File Note: %b%bThis is a description for def%b' "$grey" "$reset" "$grey" "$reset"
    is "$got" "$expected" "Print meta: single line (def.md)"

    # 2. Multi-line
    # Note: Command substitution $(...) strips the very last trailing newline.
    # Your awk adds a newline after every line.
    got="$(_about_print_meta "$base_dir/pqr/.about_file_stu.md.md" "Multi")"
    
    # Construct expected: Label(grey) + Line1(grey) + Newline + Line2(grey)
    local expected_multi="${grey}▸ Multi: ${reset}${grey}Line 1${reset}\n${grey}Line 2${reset}"
    
    # Important: Since 'got' has an interpreted newline, we must use echo -e or printf
    # to make 'expected_multi' contain a real newline character for comparison.
    expected_multi=$(printf "$expected_multi")
    
    is "$got" "$expected_multi" "Print meta: multi-line (stu.md)"

    # 3. Empty File
    got="$(_about_print_meta "$base_dir/.about_empty.md" "Empty")"
    printf -v expected '%b▸ Empty: %b' "$grey" "$reset"
    is "$got" "${expected}" "Print meta: empty file (label only)"

    say "${yellow}Testing complete for function _about_print_meta()!${reset}"
}

test_ls() {
    local got
    local expected
    local base_dir="${SCRIPT_DIR}/test_folders"

    # 1. Directory with single file and matching metadata
    (
        cd "$base_dir" || exit
        got="$(ls testing_ls)"
        printf -v expected 'file.md\n\n%b───────────────about────────────────────%b\n%b▸ file.md: %b%bthis is about file1%b' \
            "$grey" "$reset" "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "ls: single file (test_folders/testing_ls/file.md)"
    )
    tests_run=$((tests_run + 1))

    # 2. Directory with no metadata files at all (e.g. my_folder)
    (
        cd "$base_dir" || exit
        got="$(ls my_folder 2>/dev/null)"
        printf -v expected '\n%b───────────────about────────────────────%b' "$grey" "$reset"
        is "$got" "$expected" "ls: directory with no files and no metadata (test_folders/my_folder)"
    )
    tests_run=$((tests_run + 1))

    # 3. Directory with files but no matching .about_* metadata (e.g. ghi)
    (
        cd "$base_dir" || exit
        got="$(ls ghi)"
        printf -v expected 'jkl.md\nmno.md\n\n%b───────────────about────────────────────%b' "$grey" "$reset"
        is "$got" "$expected" "ls: directory with files but no .about_ metadata (test_folders/ghi)"
    )
    tests_run=$((tests_run + 1))

    # 4. Directory containing multiple non-hidden files and one .about_ metadata file (def.md + .about_file_def.md.md)
    (
        cd "$base_dir" || exit
        got="$(ls .)"
        printf -v expected '%ba\033[39;49m\033[0m\nabc.md\ndef.md\n%bghi\033[39;49m\033[0m\n%bmy_folder\033[39;49m\033[0m\n%bpqr\033[39;49m\033[0m\n%btesting_ls\033[39;49m\033[0m\n\n%b───────────────about────────────────────%b\n%b▸ def.md: %b%bThis is a description for def%b\n%b▸ pqr: %b%bthis is description of pqr directory.%b' \
            "$blue" \
            "$blue" \
            "$blue" \
            "$blue" \
            "$blue" \
            "$grey" "$reset" "$grey" "$reset" "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "ls: metadata for def.md and pqr present"
    )
    tests_run=$((tests_run + 1))

    # 5. Directory where metadata has multiple lines (.about_file_stu.md.md inside pqr)
    (
        cd "$base_dir" || exit
        got="$(ls pqr)"
        printf -v expected 'stu.md\nvwx.md\nyz.md\n\n%b───────────────about────────────────────%b\n%b▸ pqr/ (this directory): %b%bthis is description of pqr directory.%b\n%b▸ stu.md: %b%bLine 1%b\n%bLine 2%b' \
            "$grey" "$reset" "$cyan" "$reset" "$grey" "$reset" "$grey" "$reset" "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "ls: multi-line metadata file (test_folders/pqr/.about_file_stu.md.md)"
    )
    tests_run=$((tests_run + 1))

    

    say "${yellow}Testing complete for function ls()!${reset}"
}

# --- Run tests ---

test_about_meta_name
test_about_meta_path
test_about_print_meta
test_ls

say "# PASS: $tests_run tests"