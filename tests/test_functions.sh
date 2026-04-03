#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

source "${ABOUT_TRACKER_PATH}/lib/main.sh"
source "${ABOUT_TRACKER_PATH}/lib/functions.sh"

SCRIPT_DIR="${ABOUT_TRACKER_PATH}/tests"

declare -i tests_run=0 # declare -i forces the variable to be treated as an integer and allows operations like ((tests_run++))

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
    local base_dir="${SCRIPT_DIR}/folders"
    tests_run=0

    # 1. no input
    got="$(_about_meta_name "")"
    is "$got" "empty string supplied as input to _about_meta_name" "no input"

    # 2. simple file input relpath
    (
        cd "$base_dir" || exit
        got="$(_about_meta_name "./file3.txt")"
        is "$got" ".about_file3.txt.md" "simple file (file3.txt) relpath."
    )
    tests_run=$((tests_run + 1))

    # 3. simple file input abspath
    got="$(_about_meta_name "$base_dir/file3.txt")"
    is "$got" ".about_file3.txt.md" "simple file (file3.txt) abspath."

    # 4. simple dir input relpath
    (
        cd "$base_dir" || exit
        got="$(_about_meta_name "./dir1")"
        is "$got" ".about_dir1.md" "simple dir (dir1) relpath."
    )
    tests_run=$((tests_run + 1))

    # 5. simple dir input abspath
    got="$(_about_meta_name "$base_dir/dir1")"
    is "$got" ".about_dir1.md" "simple dir (dir1) abspath."

    say "${yellow}Testing complete for function _about_meta_name()!${reset}"
}

test_about_meta_path() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    tests_run=0
    
    # 1. no input
    got="$(_about_meta_path "")"
    is "$got" "./empty string supplied as input to _about_meta_name" "no input"

    # 2. simple file input relpath
    (
        cd "$base_dir" || exit
        got="$(_about_meta_path "./file3.txt")"
        is "$got" "./.about_file3.txt.md" "simple file (file3.txt) relpath."
    )
    tests_run=$((tests_run + 1))

    # 3. simple file input abspath
    got="$(_about_meta_path "$base_dir/file3.txt")"
    is "$got" "$base_dir/.about_file3.txt.md" "simple file (file3.txt) abspath."

    # 4. simple file input relpath
    (
        cd "$base_dir" || exit
        got="$(_about_meta_path "./dir1")"
        is "$got" "./.about_dir1.md" "simple dir (dir1) relpath."
    )
    tests_run=$((tests_run + 1))

    # 5. simple file input abspath
    got="$(_about_meta_path "$base_dir/dir1")"
    is "$got" "$base_dir/.about_dir1.md" "simple dir (dir1) abspath."

    say "${yellow}Testing complete for function _about_meta_path()!${reset}"
}

test_about_print_meta() {
    local got
    local base_dir="${SCRIPT_DIR}/test_folders"
    tests_run=0
    
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
    tests_run=0

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

test_cp() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    tests_run=0

    # 1. non existing input - file4.txt doesn't exist
    (
        cd "$base_dir" || exit
        cp file4.txt file5.txt 2>/dev/null
        got="$([[ ! -f "file5.txt" ]] && echo yes)"
        is "$got" "yes" "non existing file attempted to be copied"
    )
    tests_run=$((tests_run + 1))

    # 2. single file with existing metadata actually copied to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        cp file3.txt dir1
        entity_copied="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        metadata_copied="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single file with existing metadata actually copied to new location with source and target paths relative"
        # reset files (remove copied files)
        command rm dir1/file3.txt
        command rm dir1/.about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 3. single file without existing metadata actually copied to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        cp file1.txt dir1
        entity_copied="$([[ -f "dir1/file1.txt" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single file without existing metadata actually copied to new location with source and target paths relative"
        # reset files (remove copied files)
        command rm dir1/file1.txt
    )
    tests_run=$((tests_run + 1))

    # 4. single file with existing metadata renamed-copied with source and target paths relative
    (
        cd "$base_dir" || exit
        cp file3.txt file4.txt
        entity_copied="$([[ -f "file4.txt" ]] && echo yes1)"
        metadata_copied="$([[ -f ".about_file4.txt.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single file with existing metadata renamed-copied with source and target paths relative"
        # reset files (remove copied files)
        command rm file4.txt
        command rm .about_file4.txt.md
    )
    tests_run=$((tests_run + 1))
    
    # 5. single file without existing metadata actually copied to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp "${base_dir}/file1.txt" "${base_dir}/dir1"
        entity_copied="$([[ -f "dir1/file1.txt" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single file without existing metadata actually copied to new location with source and target paths absolute"
        # reset files (remove copied files)
        command rm dir1/file1.txt
    )
    tests_run=$((tests_run + 1))

    # 6. single dir with existing metadata actually copied to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        cp -r dir3 dir1
        entity_copied="$([[ -d "dir1/dir3" ]] && echo yes1)"
        metadata_copied="$([[ -f "dir1/.about_dir3.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single dir with existing metadata actually copied to new location with source and target paths relative"
        # reset files (remove copied files)
        command rm -r dir1/dir3
        command rm -r dir1/.about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 7. single dir without existing metadata actually copied to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        cp -r dir1 dir2
        entity_copied="$([[ -d "dir2/dir1" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single dir without existing metadata actually copied to new location with source and target paths relative"
        # reset
        command rm -r dir2/dir1
    )
    tests_run=$((tests_run + 1))

    # 8. single dir with existing metadata renamed-copied with source and target paths relative
    (
        cd "$base_dir" || exit
        cp -r dir3 dir4
        entity_copied="$([[ -d "dir4" ]] && echo yes1)"
        metadata_copied="$([[ -f ".about_dir4.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single dir with existing metadata renamed-copied with source and target paths relative"
        # reset
        command rm -r dir4
        command rm .about_dir4.md
    )
    tests_run=$((tests_run + 1))

    # 9. single dir without existing metadata renamed-copied with source and target paths relative
    (
        cd "$base_dir" || exit
        cp -r dir1 dir4
        entity_copied="$([[ -d "dir4" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single dir without existing metadata renamed-copied with source and target paths relative"
        # reset
        command rm -r dir4
    )
    tests_run=$((tests_run + 1))

    # 10. single dir with existing metadata actually copied to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp -r "${base_dir}/dir3" "${base_dir}/dir1"
        entity_copied="$([[ -d "dir1/dir3" ]] && echo yes1)"
        metadata_copied="$([[ -f "dir1/.about_dir3.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single dir with existing metadata actually copied to new location with source and target paths absolute"
        # reset
        command rm -r dir1/dir3
        command rm dir1/.about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 11. single file with existing metadata actually copied to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp "${base_dir}/file3.txt" "${base_dir}/dir1"
        entity_copied="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        metadata_copied="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single file with existing metadata actually copied to new location with source and target paths absolute"
        # reset
        command rm dir1/file3.txt
        command rm dir1/.about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 12. single file with existing metadata renamed-copied with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp "${base_dir}/file3.txt" "${base_dir}/file4.txt"
        entity_copied="$([[ -f "file4.txt" ]] && echo yes1)"
        metadata_copied="$([[ -f ".about_file4.txt.md" ]] && echo yes2)"
        got="${entity_copied} ${metadata_copied}"
        is "$got" "yes1 yes2" "single file with existing metadata renamed-copied with source and target paths absolute"
        # reset
        command rm file4.txt
        command rm .about_file4.txt.md
    )
    tests_run=$((tests_run + 1))

    # 13. single file without existing metadata renamed-copied with source and target paths relative
    (
        cd "$base_dir" || exit
        cp file1.txt file4.txt
        entity_copied="$([[ -f "file4.txt" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single file without existing metadata renamed-copied with source and target paths relative"
        # reset
        command rm file4.txt
    )
    tests_run=$((tests_run + 1))

    # 14. single file without existing metadata renamed-copied with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp "${base_dir}/file1.txt" "${base_dir}/file4.txt"
        entity_copied="$([[ -f "file4.txt" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single file without existing metadata renamed-copied with source and target paths absolute"
        # reset
        command rm file4.txt
    )
    tests_run=$((tests_run + 1))

    # 15. single dir without existing metadata actually copied to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        cp -r "${base_dir}/dir1" "${base_dir}/dir2"
        entity_copied="$([[ -d "dir2/dir1" ]] && echo yes)"
        got="${entity_copied}"
        is "$got" "yes" "single dir without existing metadata actually copied to new location with source and target paths absolute"
        # reset
        command rm -r dir2/dir1
    )
    tests_run=$((tests_run + 1))

    # 16. multiple files (mixed metadata) actually copied to new location with relative paths
    (
        cd "$base_dir" || exit
        cp file1.txt file3.txt dir1
        file1_copied="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        file3_copied="$([[ -f "dir1/file3.txt" ]] && echo yes2)"
        file3_meta_copied="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes3)"
        got="${file1_copied} ${file3_copied} ${file3_meta_copied}"
        is "$got" "yes1 yes2 yes3" "multiple files (mixed metadata) actually copied to new location with relative paths"
        # reset
        command rm dir1/file1.txt
        command rm dir1/file3.txt
        command rm dir1/.about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 17. multiple files (mixed metadata) actually copied to new location with absolute paths
    (
        cd "$base_dir" || exit
        cp "${base_dir}/file1.txt" "${base_dir}/file3.txt" "${base_dir}/dir1"
        file1_copied="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        file3_copied="$([[ -f "dir1/file3.txt" ]] && echo yes2)"
        file3_meta_copied="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes3)"
        got="${file1_copied} ${file3_copied} ${file3_meta_copied}"
        is "$got" "yes1 yes2 yes3" "multiple files (mixed metadata) actually copied to new location with absolute paths"
        # reset
        command rm dir1/file1.txt
        command rm dir1/file3.txt
        command rm dir1/.about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 18. multiple dirs (mixed metadata) actually copied to new location with relative paths
    (
        cd "$base_dir" || exit
        cp -r dir1 dir3 dir2
        dir1_copied="$([[ -d "dir2/dir1" ]] && echo yes1)"
        dir3_copied="$([[ -d "dir2/dir3" ]] && echo yes2)"
        dir3_meta_copied="$([[ -f "dir2/.about_dir3.md" ]] && echo yes3)"
        got="${dir1_copied} ${dir3_copied} ${dir3_meta_copied}"
        is "$got" "yes1 yes2 yes3" "multiple dirs (mixed metadata) actually copied to new location with relative paths"
        # reset
        command rm -r dir2/dir1
        command rm -r dir2/dir3
        command rm dir2/.about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 19. multiple dirs (mixed metadata) actually copied to new location with absolute paths
    (
        cd "$base_dir" || exit
        cp -r "${base_dir}/dir1" "${base_dir}/dir3" "${base_dir}/dir2"
        dir1_copied="$([[ -d "dir2/dir1" ]] && echo yes1)"
        dir3_copied="$([[ -d "dir2/dir3" ]] && echo yes2)"
        dir3_meta_copied="$([[ -f "dir2/.about_dir3.md" ]] && echo yes3)"
        got="${dir1_copied} ${dir3_copied} ${dir3_meta_copied}"
        is "$got" "yes1 yes2 yes3" "multiple dirs (mixed metadata) actually copied to new location with absolute paths"
        # reset
        command rm -r dir2/dir1
        command rm -r dir2/dir3
        command rm dir2/.about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 20. multiple mixed entities (file + dir, mixed metadata) copied to new location with relative paths
    (
        cd "$base_dir" || exit
        cp -r file3.txt dir3 dir1
        file3_copied="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        file3_meta_copied="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        dir3_copied="$([[ -d "dir1/dir3" ]] && echo yes3)"
        dir3_meta_copied="$([[ -f "dir1/.about_dir3.md" ]] && echo yes4)"
        got="${file3_copied} ${file3_meta_copied} ${dir3_copied} ${dir3_meta_copied}"
        is "$got" "yes1 yes2 yes3 yes4" "multiple mixed entities (file + dir, mixed metadata) copied to new location with relative paths"
        # reset
        command rm dir1/file3.txt
        command rm dir1/.about_file3.txt.md
        command rm -r dir1/dir3
        command rm dir1/.about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 21. non-existing source dir - dir4 doesn't exist
    (
        cd "$base_dir" || exit
        cp -r dir4 dir1 2>/dev/null
        got="$([[ ! -d "dir1/dir4" ]] && echo yes)"
        is "$got" "yes" "non existing dir attempted to be copied"
    )
    tests_run=$((tests_run + 1))
    say "${yellow}Testing complete for function cp()!${reset}"
}

test_mv() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    tests_run=0

    # 1. non existing input - file4.txt doesn't exist
    (
        cd "$base_dir" || exit
        mv file4.txt file5.txt 2>/dev/null
        got="$([[ ! -f "file5.txt" ]] && echo yes)"
        is "$got" "yes" "non existing file attempted to be moved"
    )
    tests_run=$((tests_run + 1))

    # 2. single file with existing metadata actually moved to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        mv file3.txt dir1
        entity_moved="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        metadata_moved="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        got="${entity_moved} ${metadata_moved}"
        is "$got" "yes1 yes2" "single file with existing metadata actually moved to new location with source and target paths relative"
        # reset files (bring back moved files)
        command mv dir1/file3.txt .
        command mv dir1/.about_file3.txt.md .
    )
    tests_run=$((tests_run + 1))

    # 3. single dir with existing metadata actually moved to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        mv dir3 dir1
        entity_moved="$([[ -d "dir1/dir3" ]] && echo yes1)"
        metadata_moved="$([[ -f "dir1/.about_dir3.md" ]] && echo yes2)"
        got="${entity_moved} ${metadata_moved}"
        is "$got" "yes1 yes2" "single dir with existing metadata actually moved to new location with source and target paths relative"
        # reset files (bring back moved files)
        command mv dir1/dir3 .
        command mv dir1/.about_dir3.md .
    )
    tests_run=$((tests_run + 1))

    # 4. single file without existing metadata actually moved to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        mv file1.txt dir1
        entity_moved="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        source_gone="$([[ ! -f "file1.txt" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single file without existing metadata actually moved to new location with source and target paths relative"
        # reset
        command mv dir1/file1.txt .
    )
    tests_run=$((tests_run + 1))

    # 5. single file without existing metadata actually moved to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/file1.txt" "${base_dir}/dir1"
        entity_moved="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        source_gone="$([[ ! -f "file1.txt" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single file without existing metadata actually moved to new location with source and target paths absolute"
        # reset
        command mv dir1/file1.txt .
    )
    tests_run=$((tests_run + 1))

    # 6. single file with existing metadata actually moved to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/file3.txt" "${base_dir}/dir1"
        entity_moved="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        metadata_moved="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        source_gone="$([[ ! -f "file3.txt" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single file with existing metadata actually moved to new location with source and target paths absolute"
        # reset
        command mv dir1/file3.txt .
        command mv dir1/.about_file3.txt.md .
    )
    tests_run=$((tests_run + 1))

    # 7. single file with existing metadata renamed-moved with source and target paths relative
    (
        cd "$base_dir" || exit
        mv file3.txt file4.txt
        entity_moved="$([[ -f "file4.txt" ]] && echo yes1)"
        metadata_moved="$([[ -f ".about_file4.txt.md" ]] && echo yes2)"
        source_gone="$([[ ! -f "file3.txt" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single file with existing metadata renamed-moved with source and target paths relative"
        # reset
        command mv file4.txt file3.txt
        command mv .about_file4.txt.md .about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 8. single file without existing metadata renamed-moved with source and target paths relative
    (
        cd "$base_dir" || exit
        mv file1.txt file4.txt
        entity_moved="$([[ -f "file4.txt" ]] && echo yes1)"
        source_gone="$([[ ! -f "file1.txt" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single file without existing metadata renamed-moved with source and target paths relative"
        # reset
        command mv file4.txt file1.txt
    )
    tests_run=$((tests_run + 1))

    # 9. single file with existing metadata renamed-moved with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/file3.txt" "${base_dir}/file4.txt"
        entity_moved="$([[ -f "file4.txt" ]] && echo yes1)"
        metadata_moved="$([[ -f ".about_file4.txt.md" ]] && echo yes2)"
        source_gone="$([[ ! -f "file3.txt" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single file with existing metadata renamed-moved with source and target paths absolute"
        # reset
        command mv file4.txt file3.txt
        command mv .about_file4.txt.md .about_file3.txt.md
    )
    tests_run=$((tests_run + 1))

    # 10. single file without existing metadata renamed-moved with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/file1.txt" "${base_dir}/file4.txt"
        entity_moved="$([[ -f "file4.txt" ]] && echo yes1)"
        source_gone="$([[ ! -f "file1.txt" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single file without existing metadata renamed-moved with source and target paths absolute"
        # reset
        command mv file4.txt file1.txt
    )
    tests_run=$((tests_run + 1))

    # 11. single dir without existing metadata actually moved to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        mv dir1 dir2
        entity_moved="$([[ -d "dir2/dir1" ]] && echo yes1)"
        source_gone="$([[ ! -d "dir1" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single dir without existing metadata actually moved to new location with source and target paths relative"
        # reset
        command mv dir2/dir1 .
    )
    tests_run=$((tests_run + 1))

    # 12. single dir without existing metadata actually moved to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/dir1" "${base_dir}/dir2"
        entity_moved="$([[ -d "dir2/dir1" ]] && echo yes1)"
        source_gone="$([[ ! -d "dir1" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single dir without existing metadata actually moved to new location with source and target paths absolute"
        # reset
        command mv dir2/dir1 .
    )
    tests_run=$((tests_run + 1))

    # 13. single dir with existing metadata actually moved to new location with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/dir3" "${base_dir}/dir1"
        entity_moved="$([[ -d "dir1/dir3" ]] && echo yes1)"
        metadata_moved="$([[ -f "dir1/.about_dir3.md" ]] && echo yes2)"
        source_gone="$([[ ! -d "dir3" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single dir with existing metadata actually moved to new location with source and target paths absolute"
        # reset
        command mv dir1/dir3 .
        command mv dir1/.about_dir3.md .
    )
    tests_run=$((tests_run + 1))

    # 14. single dir with existing metadata renamed-moved with source and target paths relative
    (
        cd "$base_dir" || exit
        mv dir3 dir4
        entity_moved="$([[ -d "dir4" ]] && echo yes1)"
        metadata_moved="$([[ -f ".about_dir4.md" ]] && echo yes2)"
        source_gone="$([[ ! -d "dir3" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single dir with existing metadata renamed-moved with source and target paths relative"
        # reset
        command mv dir4 dir3
        command mv .about_dir4.md .about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 15. single dir without existing metadata renamed-moved with source and target paths relative
    (
        cd "$base_dir" || exit
        mv dir1 dir4
        entity_moved="$([[ -d "dir4" ]] && echo yes1)"
        source_gone="$([[ ! -d "dir1" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single dir without existing metadata renamed-moved with source and target paths relative"
        # reset
        command mv dir4 dir1
    )
    tests_run=$((tests_run + 1))

    # 16. single dir with existing metadata renamed-moved with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/dir3" "${base_dir}/dir4"
        entity_moved="$([[ -d "dir4" ]] && echo yes1)"
        metadata_moved="$([[ -f ".about_dir4.md" ]] && echo yes2)"
        source_gone="$([[ ! -d "dir3" ]] && echo yes3)"
        source_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes4)"
        got="${entity_moved} ${metadata_moved} ${source_gone} ${source_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4" "single dir with existing metadata renamed-moved with source and target paths absolute"
        # reset
        command mv dir4 dir3
        command mv .about_dir4.md .about_dir3.md
    )
    tests_run=$((tests_run + 1))

    # 17. single dir without existing metadata renamed-moved with source and target paths absolute
    (
        cd "$base_dir" || exit
        mv "${base_dir}/dir1" "${base_dir}/dir4"
        entity_moved="$([[ -d "dir4" ]] && echo yes1)"
        source_gone="$([[ ! -d "dir1" ]] && echo yes2)"
        got="${entity_moved} ${source_gone}"
        is "$got" "yes1 yes2" "single dir without existing metadata renamed-moved with source and target paths absolute"
        # reset
        command mv dir4 dir1
    )
    tests_run=$((tests_run + 1))

    # 18. multiple files (mixed metadata) actually moved to new location with relative paths
    (
        cd "$base_dir" || exit
        mv file1.txt file3.txt dir1
        file1_moved="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        file3_moved="$([[ -f "dir1/file3.txt" ]] && echo yes2)"
        file3_meta_moved="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes3)"
        file1_gone="$([[ ! -f "file1.txt" ]] && echo yes4)"
        file3_gone="$([[ ! -f "file3.txt" ]] && echo yes5)"
        file3_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes6)"
        got="${file1_moved} ${file3_moved} ${file3_meta_moved} ${file1_gone} ${file3_gone} ${file3_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4 yes5 yes6" "multiple files (mixed metadata) actually moved to new location with relative paths"
        # reset
        command mv dir1/file1.txt .
        command mv dir1/file3.txt .
        command mv dir1/.about_file3.txt.md .
    )
    tests_run=$((tests_run + 1))

    # 19. multiple files (mixed metadata) actually moved to new location with absolute paths
    (
        cd "$base_dir" || exit
        mv "${base_dir}/file1.txt" "${base_dir}/file3.txt" "${base_dir}/dir1"
        file1_moved="$([[ -f "dir1/file1.txt" ]] && echo yes1)"
        file3_moved="$([[ -f "dir1/file3.txt" ]] && echo yes2)"
        file3_meta_moved="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes3)"
        file1_gone="$([[ ! -f "file1.txt" ]] && echo yes4)"
        file3_gone="$([[ ! -f "file3.txt" ]] && echo yes5)"
        file3_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes6)"
        got="${file1_moved} ${file3_moved} ${file3_meta_moved} ${file1_gone} ${file3_gone} ${file3_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4 yes5 yes6" "multiple files (mixed metadata) actually moved to new location with absolute paths"
        # reset
        command mv dir1/file1.txt .
        command mv dir1/file3.txt .
        command mv dir1/.about_file3.txt.md .
    )
    tests_run=$((tests_run + 1))

    # 20. multiple dirs (mixed metadata) actually moved to new location with relative paths
    (
        cd "$base_dir" || exit
        mv dir1 dir3 dir2
        dir1_moved="$([[ -d "dir2/dir1" ]] && echo yes1)"
        dir3_moved="$([[ -d "dir2/dir3" ]] && echo yes2)"
        dir3_meta_moved="$([[ -f "dir2/.about_dir3.md" ]] && echo yes3)"
        dir1_gone="$([[ ! -d "dir1" ]] && echo yes4)"
        dir3_gone="$([[ ! -d "dir3" ]] && echo yes5)"
        dir3_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes6)"
        got="${dir1_moved} ${dir3_moved} ${dir3_meta_moved} ${dir1_gone} ${dir3_gone} ${dir3_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4 yes5 yes6" "multiple dirs (mixed metadata) actually moved to new location with relative paths"
        # reset
        command mv dir2/dir1 .
        command mv dir2/dir3 .
        command mv dir2/.about_dir3.md .
    )
    tests_run=$((tests_run + 1))

    # 21. multiple dirs (mixed metadata) actually moved to new location with absolute paths
    (
        cd "$base_dir" || exit
        mv "${base_dir}/dir1" "${base_dir}/dir3" "${base_dir}/dir2"
        dir1_moved="$([[ -d "dir2/dir1" ]] && echo yes1)"
        dir3_moved="$([[ -d "dir2/dir3" ]] && echo yes2)"
        dir3_meta_moved="$([[ -f "dir2/.about_dir3.md" ]] && echo yes3)"
        dir1_gone="$([[ ! -d "dir1" ]] && echo yes4)"
        dir3_gone="$([[ ! -d "dir3" ]] && echo yes5)"
        dir3_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes6)"
        got="${dir1_moved} ${dir3_moved} ${dir3_meta_moved} ${dir1_gone} ${dir3_gone} ${dir3_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4 yes5 yes6" "multiple dirs (mixed metadata) actually moved to new location with absolute paths"
        # reset
        command mv dir2/dir1 .
        command mv dir2/dir3 .
        command mv dir2/.about_dir3.md .
    )
    tests_run=$((tests_run + 1))

    # 22. multiple mixed entities (file + dir, mixed metadata) moved to new location with relative paths
    (
        cd "$base_dir" || exit
        mv file3.txt dir3 dir1
        file3_moved="$([[ -f "dir1/file3.txt" ]] && echo yes1)"
        file3_meta_moved="$([[ -f "dir1/.about_file3.txt.md" ]] && echo yes2)"
        dir3_moved="$([[ -d "dir1/dir3" ]] && echo yes3)"
        dir3_meta_moved="$([[ -f "dir1/.about_dir3.md" ]] && echo yes4)"
        file3_gone="$([[ ! -f "file3.txt" ]] && echo yes5)"
        file3_meta_gone="$([[ ! -f ".about_file3.txt.md" ]] && echo yes6)"
        dir3_gone="$([[ ! -d "dir3" ]] && echo yes7)"
        dir3_meta_gone="$([[ ! -f ".about_dir3.md" ]] && echo yes8)"
        got="${file3_moved} ${file3_meta_moved} ${dir3_moved} ${dir3_meta_moved} ${file3_gone} ${file3_meta_gone} ${dir3_gone} ${dir3_meta_gone}"
        is "$got" "yes1 yes2 yes3 yes4 yes5 yes6 yes7 yes8" "multiple mixed entities (file + dir, mixed metadata) moved to new location with relative paths"
        # reset
        command mv dir1/file3.txt .
        command mv dir1/.about_file3.txt.md .
        command mv dir1/dir3 .
        command mv dir1/.about_dir3.md .
    )
    tests_run=$((tests_run + 1))

    # 23. non-existing source dir - dir4 doesn't exist
    (
        cd "$base_dir" || exit
        mv dir4 dir1 2>/dev/null
        got="$([[ ! -d "dir1/dir4" ]] && echo yes)"
        is "$got" "yes" "non existing dir attempted to be moved"
    )
    tests_run=$((tests_run + 1))

    say "${yellow}Testing complete for function mv()!${reset}"
}

# --- Run tests ---

# test_about_meta_name
# test_about_meta_path
# test_about_print_meta
# test_ls
# test_cp
test_mv

# say "# PASS: $tests_run tests"