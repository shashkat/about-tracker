#!/usr/bin/env bats

# Tests for the helper functions in lib/functions.sh

load test_helper

setup() {
    setup_fixtures
}

# --- _about_meta_name ---

@test "_about_meta_name: no input" {
    run _about_meta_name ""
    [ "$status" -eq 1 ]
    [ "$output" = "empty string supplied as input to _about_meta_name" ]
}

@test "_about_meta_name: simple file (file3.txt) relpath" {
    run _about_meta_name "./file3.txt"
    [ "$output" = ".about_file3.txt.md" ]
}

@test "_about_meta_name: simple file (file3.txt) abspath" {
    run _about_meta_name "${WORK_DIR}/file3.txt"
    [ "$output" = ".about_file3.txt.md" ]
}

@test "_about_meta_name: simple dir (dir1) relpath" {
    run _about_meta_name "./dir1"
    [ "$output" = ".about_dir1.md" ]
}

@test "_about_meta_name: simple dir (dir1) abspath" {
    run _about_meta_name "${WORK_DIR}/dir1"
    [ "$output" = ".about_dir1.md" ]
}

# --- _about_meta_path ---

@test "_about_meta_path: no input" {
    run _about_meta_path ""
    [ "$output" = "./empty string supplied as input to _about_meta_name" ]
}

@test "_about_meta_path: simple file (file3.txt) relpath" {
    run _about_meta_path "./file3.txt"
    [ "$output" = "./.about_file3.txt.md" ]
}

@test "_about_meta_path: simple file (file3.txt) abspath" {
    run _about_meta_path "${WORK_DIR}/file3.txt"
    [ "$output" = "${WORK_DIR}/.about_file3.txt.md" ]
}

@test "_about_meta_path: simple dir (dir1) relpath" {
    run _about_meta_path "./dir1"
    [ "$output" = "./.about_dir1.md" ]
}

@test "_about_meta_path: simple dir (dir1) abspath" {
    run _about_meta_path "${WORK_DIR}/dir1"
    [ "$output" = "${WORK_DIR}/.about_dir1.md" ]
}

# --- _about_print_meta ---

@test "_about_print_meta: single line" {
    run _about_print_meta ".about_file3.txt.md" "File Note"
    printf -v expected '%b▸ File Note: %b%bthis is about file3.txt%b' "$grey" "$reset" "$grey" "$reset"
    [ "$output" = "$expected" ]
}

@test "_about_print_meta: multi-line" {
    printf 'Line 1\nLine 2\n' > .about_multi.md
    run _about_print_meta ".about_multi.md" "Multi"
    printf -v expected '%b▸ Multi: %b%bLine 1%b\n%bLine 2%b' "$grey" "$reset" "$grey" "$reset" "$grey" "$reset"
    [ "$output" = "$expected" ]
}

@test "_about_print_meta: empty file (label only)" {
    touch .about_empty.md
    run _about_print_meta ".about_empty.md" "Empty"
    printf -v expected '%b▸ Empty: %b' "$grey" "$reset"
    [ "$output" = "$expected" ]
}

@test "_about_print_meta: missing file prints nothing" {
    run _about_print_meta ".about_does_not_exist.md" "Missing"
    [ -z "$output" ]
}
