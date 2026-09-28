#!/usr/bin/env bats

# Tests for `abt doctor`

load test_helper

setup() {
    setup_fixtures
}

@test "no orphans in fixtures (current directory by default)" {
    run abt doctor
    [ "$status" -eq 0 ]
    printf -v expected '%bNo orphaned metadata files found in .%b' "$green" "$reset"
    [ "$output" = "$expected" ]
}

@test "file moved without abt leaves an orphan" {
    command mv file3.txt dir1/
    run abt doctor .
    [ "$status" -eq 1 ]
    printf -v expected '%b⚠  Found 1 orphaned metadata file(s) in . (the file/directory they describe does not exist):%b\n   %b./.about_file3.txt.md%b  (missing: file3.txt)' \
        "$yellow" "$reset" "$yellow" "$reset"
    [ "$output" = "$expected" ]
}

@test "directory renamed without abt leaves an orphan" {
    command mv dir3 dir3_renamed
    run abt doctor
    [ "$status" -eq 1 ]
    [[ "$output" == *"./.about_dir3.md"*"(missing: dir3)"* ]]
}

@test "multiple orphans are all reported, valid metadata is not" {
    command rm file3.txt
    command rm -r dir3
    touch .about_file1.txt.md # file1.txt exists, so this is not an orphan
    run abt doctor
    [ "$status" -eq 1 ]
    [[ "$output" == *"Found 2 orphaned"* ]]
    [[ "$output" == *"(missing: dir3)"* ]]
    [[ "$output" == *"(missing: file3.txt)"* ]]
    [[ "$output" != *"file1.txt"* ]]
}

@test "checks the given directory, trailing slash stripped" {
    touch dir1/.about_gone.txt.md
    run abt doctor dir1/
    [ "$status" -eq 1 ]
    [[ "$output" == *"in dir1 "* ]]
    [[ "$output" == *"dir1/.about_gone.txt.md"*"(missing: gone.txt)"* ]]
}

@test "names with spaces are handled" {
    touch "my file.txt" ".about_my file.txt.md" ".about_old name.md"
    run abt doctor
    [ "$status" -eq 1 ]
    [[ "$output" == *"Found 1 orphaned"* ]]
    [[ "$output" == *"(missing: old name)"* ]]
}

@test "broken symlink is not treated as missing" {
    ln -s does_not_exist link
    touch .about_link.md
    run abt doctor
    [ "$status" -eq 0 ]
}

@test "without -r, orphans in subdirectories are not reported" {
    touch dir1/.about_gone.txt.md
    run abt doctor
    [ "$status" -eq 0 ]
}

@test "-r finds orphans in nested subdirectories" {
    mkdir -p dir1/sub/deeper
    touch dir1/.about_gone.txt.md dir1/sub/deeper/.about_lost.md
    run abt doctor -r
    [ "$status" -eq 1 ]
    printf -v expected '%b⚠  Found 2 orphaned metadata file(s) in . and its subdirectories (the file/directory they describe does not exist):%b\n   %b./dir1/.about_gone.txt.md%b  (missing: gone.txt)\n   %b./dir1/sub/deeper/.about_lost.md%b  (missing: lost)' \
        "$yellow" "$reset" "$yellow" "$reset" "$yellow" "$reset"
    [ "$output" = "$expected" ]
}

@test "-r checks each metadata file against its own directory" {
    # after the move, a file3.txt exists in dir2, but that must not make the top level .about_file3.txt.md count as valid
    command mv file3.txt dir2/
    touch dir2/.about_dir2_file.txt.md # valid, dir2_file.txt is next to it
    run abt doctor -r
    [ "$status" -eq 1 ]
    [[ "$output" == *"Found 1 orphaned"* ]]
    [[ "$output" == *"./.about_file3.txt.md"*"(missing: file3.txt)"* ]]
}

@test "-r with no orphans anywhere" {
    touch dir1/.about_dir1_file.txt.md
    run abt doctor -r
    [ "$status" -eq 0 ]
    printf -v expected '%bNo orphaned metadata files found in . and its subdirectories%b' "$green" "$reset"
    [ "$output" = "$expected" ]
}

@test "-r works after the directory argument too" {
    mkdir dir1/sub
    touch dir1/sub/.about_gone.md
    run abt doctor dir1 -r
    [ "$status" -eq 1 ]
    [[ "$output" == *"dir1/sub/.about_gone.md"*"(missing: gone)"* ]]
}

@test "-r does not follow symlinked directories" {
    mkdir outside
    touch outside/.about_gone.md
    ln -s ../outside dir1/link_to_outside
    run abt doctor -r dir1
    [ "$status" -eq 0 ]
}

@test "unknown option is an error" {
    run abt doctor -x
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown option '-x'"* ]]
}

@test "non-existent directory is an error" {
    run abt doctor no_such_dir
    [ "$status" -eq 2 ]
    [ "$output" = "Error: 'no_such_dir' is not a directory." ]
}

@test "file instead of directory is an error" {
    run abt doctor file1.txt
    [ "$status" -eq 2 ]
}

@test "too many arguments is an error" {
    run abt doctor dir1 dir2
    [ "$status" -eq 2 ]
}
