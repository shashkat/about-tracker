#!/usr/bin/env bats

# Tests for `abt mv`. Each test starts from a fresh copy of tests/fixtures (see setup_fixtures in test_helper.bash),
# so nothing needs to be moved back afterwards.

load test_helper

setup() {
    setup_fixtures
}

@test "non existing file attempted to be moved" {
    run abt mv file4.txt file5.txt
    [ "$status" -ne 0 ]
    [ ! -e file5.txt ]
}

@test "single file with existing metadata actually moved to new location with source and target paths relative" {
    abt mv file3.txt dir1
    [ -f dir1/file3.txt ]
    [ -f dir1/.about_file3.txt.md ]
}

@test "single dir with existing metadata actually moved to new location with source and target paths relative" {
    abt mv dir3 dir1
    [ -d dir1/dir3 ]
    [ -f dir1/.about_dir3.md ]
}

@test "single file without existing metadata actually moved to new location with source and target paths relative" {
    abt mv file1.txt dir1
    [ -f dir1/file1.txt ]
    [ ! -e file1.txt ]
}

@test "single file without existing metadata actually moved to new location with source and target paths absolute" {
    abt mv "${WORK_DIR}/file1.txt" "${WORK_DIR}/dir1"
    [ -f dir1/file1.txt ]
    [ ! -e file1.txt ]
}

@test "single file with existing metadata actually moved to new location with source and target paths absolute" {
    abt mv "${WORK_DIR}/file3.txt" "${WORK_DIR}/dir1"
    [ -f dir1/file3.txt ]
    [ -f dir1/.about_file3.txt.md ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
}

@test "single file with existing metadata renamed-moved with source and target paths relative" {
    abt mv file3.txt file4.txt
    [ -f file4.txt ]
    [ -f .about_file4.txt.md ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
}

@test "single file without existing metadata renamed-moved with source and target paths relative" {
    abt mv file1.txt file4.txt
    [ -f file4.txt ]
    [ ! -e file1.txt ]
}

@test "single file with existing metadata renamed-moved with source and target paths absolute" {
    abt mv "${WORK_DIR}/file3.txt" "${WORK_DIR}/file4.txt"
    [ -f file4.txt ]
    [ -f .about_file4.txt.md ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
}

@test "single file without existing metadata renamed-moved with source and target paths absolute" {
    abt mv "${WORK_DIR}/file1.txt" "${WORK_DIR}/file4.txt"
    [ -f file4.txt ]
    [ ! -e file1.txt ]
}

@test "single dir without existing metadata actually moved to new location with source and target paths relative" {
    abt mv dir1 dir2
    [ -d dir2/dir1 ]
    [ ! -e dir1 ]
}

@test "single dir without existing metadata actually moved to new location with source and target paths absolute" {
    abt mv "${WORK_DIR}/dir1" "${WORK_DIR}/dir2"
    [ -d dir2/dir1 ]
    [ ! -e dir1 ]
}

@test "single dir with existing metadata actually moved to new location with source and target paths absolute" {
    abt mv "${WORK_DIR}/dir3" "${WORK_DIR}/dir1"
    [ -d dir1/dir3 ]
    [ -f dir1/.about_dir3.md ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "single dir with existing metadata renamed-moved with source and target paths relative" {
    abt mv dir3 dir4
    [ -d dir4 ]
    [ -f .about_dir4.md ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "single dir without existing metadata renamed-moved with source and target paths relative" {
    abt mv dir1 dir4
    [ -d dir4 ]
    [ ! -e dir1 ]
}

@test "single dir with existing metadata renamed-moved with source and target paths absolute" {
    abt mv "${WORK_DIR}/dir3" "${WORK_DIR}/dir4"
    [ -d dir4 ]
    [ -f .about_dir4.md ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "single dir without existing metadata renamed-moved with source and target paths absolute" {
    abt mv "${WORK_DIR}/dir1" "${WORK_DIR}/dir4"
    [ -d dir4 ]
    [ ! -e dir1 ]
}

@test "multiple files (mixed metadata) actually moved to new location with relative paths" {
    abt mv file1.txt file3.txt dir1
    [ -f dir1/file1.txt ]
    [ -f dir1/file3.txt ]
    [ -f dir1/.about_file3.txt.md ]
    [ ! -e file1.txt ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
}

@test "multiple files (mixed metadata) actually moved to new location with absolute paths" {
    abt mv "${WORK_DIR}/file1.txt" "${WORK_DIR}/file3.txt" "${WORK_DIR}/dir1"
    [ -f dir1/file1.txt ]
    [ -f dir1/file3.txt ]
    [ -f dir1/.about_file3.txt.md ]
    [ ! -e file1.txt ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
}

@test "multiple dirs (mixed metadata) actually moved to new location with relative paths" {
    abt mv dir1 dir3 dir2
    [ -d dir2/dir1 ]
    [ -d dir2/dir3 ]
    [ -f dir2/.about_dir3.md ]
    [ ! -e dir1 ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "multiple dirs (mixed metadata) actually moved to new location with absolute paths" {
    abt mv "${WORK_DIR}/dir1" "${WORK_DIR}/dir3" "${WORK_DIR}/dir2"
    [ -d dir2/dir1 ]
    [ -d dir2/dir3 ]
    [ -f dir2/.about_dir3.md ]
    [ ! -e dir1 ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "multiple mixed entities (file + dir, mixed metadata) moved to new location with relative paths" {
    abt mv file3.txt dir3 dir1
    [ -f dir1/file3.txt ]
    [ -f dir1/.about_file3.txt.md ]
    [ -d dir1/dir3 ]
    [ -f dir1/.about_dir3.md ]
    [ ! -e file3.txt ]
    [ ! -e .about_file3.txt.md ]
    [ ! -e dir3 ]
    [ ! -e .about_dir3.md ]
}

@test "non existing dir attempted to be moved" {
    run abt mv dir4 dir1
    [ "$status" -ne 0 ]
    [ ! -e dir1/dir4 ]
}
