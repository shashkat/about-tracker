#!/usr/bin/env bash

# Although at this point, ABOUT_TRACKER_PATH variable should generally exist only, but just to be sure, 
# I check here again.
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

export PATH="${ABOUT_TRACKER_PATH}/bin:${PATH}" # makes the abt command available
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
    local start_time end_time elapsed
    tests_run=0

    start_time=$(date +%s.%N)

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

    end_time=$(date +%s.%N)
    elapsed=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN { printf "%.3f", e - s }')

    say "${yellow}Testing complete for function _about_meta_name()! Took ${elapsed}s.${reset}"
}

test_about_meta_path() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    local start_time end_time elapsed
    tests_run=0

    start_time=$(date +%s.%N)
    
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

    end_time=$(date +%s.%N)
    elapsed=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN { printf "%.3f", e - s }')

    say "${yellow}Testing complete for function _about_meta_path()! Took ${elapsed}s.${reset}"
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
    local base_dir="${SCRIPT_DIR}/folders"
    local start_time end_time elapsed
    tests_run=0

    start_time=$(date +%s.%N)

    # 1. directory without own and inside metadata
    (
        cd "$base_dir" || exit
        cd dir1
        got="$(abt ls)"
        printf -v expected 'dir1_file.txt\n\n%b───────────────about────────────────────%b' "$grey" "$reset"
        is "$got" "$expected" "directory without own and inside metadata"
    )
    tests_run=$((tests_run + 1))

    # 2. directory with its own metadata but no inside metadata
    (
        cd "$base_dir" || exit
        cd dir3
        got="$(abt ls)"
        printf -v expected 'dir3_file.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3/ (this directory): %b%bthis is about dir3%b' \
            "$grey" "$reset" "$cyan" "$reset" "$grey" "$reset"
        is "$got" "$expected" "directory with its own metadata but no inside metadata"
    )
    tests_run=$((tests_run + 1))

    # 3. directory without its own metadata but with multiple inside metadata
    (
        cd "$base_dir" || exit
        got="$(abt ls)"
        printf -v expected '%bdir1%b%b\n%bdir2%b%b\n%bdir3%b%b\nfile1.txt\nfile2.txt\nfile3.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3: %b%bthis is about dir3%b\n%b▸ file3.txt: %b%bthis is about file3.txt%b' \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "directory without its own metadata but with multiple inside metadata"
    )
    tests_run=$((tests_run + 1))

    # 4. directory without its own metadata but with multiple inside metadata - run 2
    (
        cd "$base_dir" || exit
        got="$(abt ls)"
        printf -v expected '%bdir1%b%b\n%bdir2%b%b\n%bdir3%b%b\nfile1.txt\nfile2.txt\nfile3.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3: %b%bthis is about dir3%b\n%b▸ file3.txt: %b%bthis is about file3.txt%b' \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "directory without its own metadata but with multiple inside metadata  - run 2"
    )
    tests_run=$((tests_run + 1))
    # 5. directory without its own metadata but with multiple inside metadata
    (
        cd "$base_dir" || exit
        got="$(abt ls)"
        printf -v expected '%bdir1%b%b\n%bdir2%b%b\n%bdir3%b%b\nfile1.txt\nfile2.txt\nfile3.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3: %b%bthis is about dir3%b\n%b▸ file3.txt: %b%bthis is about file3.txt%b' \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "directory without its own metadata but with multiple inside metadata  - run 3"
    )
    tests_run=$((tests_run + 1))
    # 6. directory without its own metadata but with multiple inside metadata
    (
        cd "$base_dir" || exit
        got="$(abt ls)"
        printf -v expected '%bdir1%b%b\n%bdir2%b%b\n%bdir3%b%b\nfile1.txt\nfile2.txt\nfile3.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3: %b%bthis is about dir3%b\n%b▸ file3.txt: %b%bthis is about file3.txt%b' \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$blue" "$reset2" "$reset" \
            "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset" \
            "$grey" "$reset" "$grey" "$reset"
        is "$got" "$expected" "directory without its own metadata but with multiple inside metadata  - run 4"
    )
    tests_run=$((tests_run + 1))

    end_time=$(date +%s.%N)
    elapsed=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN { printf "%.3f", e - s }')

    say "${yellow}Testing complete for function ls()! Took ${elapsed}s.${reset}"
}

test_cp() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    local start_time end_time elapsed
    tests_run=0

    start_time=$(date +%s.%N)

    # 1. non existing input - file4.txt doesn't exist
    (
        cd "$base_dir" || exit
        abt cp file4.txt file5.txt 2>/dev/null
        got="$([[ ! -f "file5.txt" ]] && echo yes)"
        is "$got" "yes" "non existing file attempted to be copied"
    )
    tests_run=$((tests_run + 1))

    # 2. single file with existing metadata actually copied to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        abt cp file3.txt dir1
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
        abt cp file1.txt dir1
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
        abt cp file3.txt file4.txt
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
        abt cp "${base_dir}/file1.txt" "${base_dir}/dir1"
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
        abt cp -r dir3 dir1
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
        abt cp -r dir1 dir2
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
        abt cp -r dir3 dir4
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
        abt cp -r dir1 dir4
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
        abt cp -r "${base_dir}/dir3" "${base_dir}/dir1"
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
        abt cp "${base_dir}/file3.txt" "${base_dir}/dir1"
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
        abt cp "${base_dir}/file3.txt" "${base_dir}/file4.txt"
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
        abt cp file1.txt file4.txt
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
        abt cp "${base_dir}/file1.txt" "${base_dir}/file4.txt"
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
        abt cp -r "${base_dir}/dir1" "${base_dir}/dir2"
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
        abt cp file1.txt file3.txt dir1
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
        abt cp "${base_dir}/file1.txt" "${base_dir}/file3.txt" "${base_dir}/dir1"
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
        abt cp -r dir1 dir3 dir2
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
        abt cp -r "${base_dir}/dir1" "${base_dir}/dir3" "${base_dir}/dir2"
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
        abt cp -r file3.txt dir3 dir1
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
        abt cp -r dir4 dir1 2>/dev/null
        got="$([[ ! -d "dir1/dir4" ]] && echo yes)"
        is "$got" "yes" "non existing dir attempted to be copied"
    )
    tests_run=$((tests_run + 1))
    end_time=$(date +%s.%N)
    elapsed=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN { printf "%.3f", e - s }')

    say "${yellow}Testing complete for function cp()! Took ${elapsed}s.${reset}"
}

test_mv() {
    local got
    local base_dir="${SCRIPT_DIR}/folders"
    local start_time end_time elapsed
    tests_run=0

    start_time=$(date +%s.%N)

    # 1. non existing input - file4.txt doesn't exist
    (
        cd "$base_dir" || exit
        abt mv file4.txt file5.txt 2>/dev/null
        got="$([[ ! -f "file5.txt" ]] && echo yes)"
        is "$got" "yes" "non existing file attempted to be moved"
    )
    tests_run=$((tests_run + 1))

    # 2. single file with existing metadata actually moved to new location with source and target paths relative
    (
        cd "$base_dir" || exit
        abt mv file3.txt dir1
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
        abt mv dir3 dir1
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
        abt mv file1.txt dir1
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
        abt mv "${base_dir}/file1.txt" "${base_dir}/dir1"
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
        abt mv "${base_dir}/file3.txt" "${base_dir}/dir1"
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
        abt mv file3.txt file4.txt
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
        abt mv file1.txt file4.txt
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
        abt mv "${base_dir}/file3.txt" "${base_dir}/file4.txt"
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
        abt mv "${base_dir}/file1.txt" "${base_dir}/file4.txt"
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
        abt mv dir1 dir2
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
        abt mv "${base_dir}/dir1" "${base_dir}/dir2"
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
        abt mv "${base_dir}/dir3" "${base_dir}/dir1"
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
        abt mv dir3 dir4
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
        abt mv dir1 dir4
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
        abt mv "${base_dir}/dir3" "${base_dir}/dir4"
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
        abt mv "${base_dir}/dir1" "${base_dir}/dir4"
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
        abt mv file1.txt file3.txt dir1
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
        abt mv "${base_dir}/file1.txt" "${base_dir}/file3.txt" "${base_dir}/dir1"
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
        abt mv dir1 dir3 dir2
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
        abt mv "${base_dir}/dir1" "${base_dir}/dir3" "${base_dir}/dir2"
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
        abt mv file3.txt dir3 dir1
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
        abt mv dir4 dir1 2>/dev/null
        got="$([[ ! -d "dir1/dir4" ]] && echo yes)"
        is "$got" "yes" "non existing dir attempted to be moved"
    )
    tests_run=$((tests_run + 1))

    end_time=$(date +%s.%N)
    elapsed=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN { printf "%.3f", e - s }')

    say "${yellow}Testing complete for function mv()! Took ${elapsed}s.${reset}"
}

# --- Run tests ---

test_about_meta_name
test_about_meta_path
# test_about_print_meta
test_ls
test_cp
test_mv

# say "# PASS: $tests_run tests"