#!/usr/bin/env bats

# Tests for `abt help`

load test_helper

@test "abt help prints the overview listing every command" {
    run abt help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: abt <command> [args...]" ]
    for cmd in ls modify cp mv rm doctor help; do
        [[ "$output" == *$'\n'"  ${cmd} "* ]]
    done
}

@test "abt --help and abt -h print the same overview as abt help" {
    expected="$(abt help)"
    run abt --help
    [ "$output" = "$expected" ]
    run abt -h
    [ "$output" = "$expected" ]
}

@test "abt help <command> prints detailed help for every command" {
    for cmd in ls modify cp mv rm doctor help; do
        run abt help "$cmd"
        [ "$status" -eq 0 ]
        [[ "${lines[0]}" == "Usage: abt ${cmd}"* ]]
    done
}

@test "abt help with an unknown command fails" {
    run abt help foo
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "abt: no help for unknown command 'foo'" ]
}
