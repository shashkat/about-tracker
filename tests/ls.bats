#!/usr/bin/env bats

# Tests for `abt ls`

load test_helper

setup() {
    setup_fixtures
}

@test "directory without own and inside metadata" {
    cd dir1
    run abt ls
    printf -v expected 'dir1_file.txt\n\n%b───────────────about────────────────────%b' "$grey" "$reset"
    [ "$output" = "$expected" ]
}

@test "directory with its own metadata but no inside metadata" {
    cd dir3
    run abt ls
    printf -v expected 'dir3_file.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3/ (this directory): %b%bthis is about dir3%b' \
        "$grey" "$reset" "$cyan" "$reset" "$grey" "$reset"
    [ "$output" = "$expected" ]
}

@test "directory without its own metadata but with multiple inside metadata" {
    run abt ls
    printf -v expected '%bdir1%b%b\n%bdir2%b%b\n%bdir3%b%b\nfile1.txt\nfile2.txt\nfile3.txt\n\n%b───────────────about────────────────────%b\n%b▸ dir3: %b%bthis is about dir3%b\n%b▸ file3.txt: %b%bthis is about file3.txt%b' \
        "$blue" "$reset2" "$reset" \
        "$blue" "$reset2" "$reset" \
        "$blue" "$reset2" "$reset" \
        "$grey" "$reset" \
        "$grey" "$reset" "$grey" "$reset" \
        "$grey" "$reset" "$grey" "$reset"
    [ "$output" = "$expected" ]
}
