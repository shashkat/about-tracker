#!/usr/bin/env bats

# Tests for the tab completion in completions/abt.sh

load test_helper

# Simulate pressing TAB after typing $1 in bash, and print the suggestions bash would get, space separated
complete_bash() {
    bash -c '
        source "${ABOUT_TRACKER_PATH}/completions/abt.sh"
        read -ra COMP_WORDS <<< "$1"
        [[ "$1" == *" " ]] && COMP_WORDS+=("") # a trailing space means a new, empty word is being completed
        COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
        _abt
        echo "${COMPREPLY[*]}"
    ' _ "$1"
}

@test "bash: abt <TAB> lists all subcommands" {
    run complete_bash "abt "
    [ "$status" -eq 0 ]
    [ "$output" = "cp doctor ls modify mv rm help" ]
}

@test "bash: abt l<TAB> completes to ls" {
    run complete_bash "abt l"
    [ "$output" = "ls" ]
}

@test "bash: abt m<TAB> lists modify and mv" {
    run complete_bash "abt m"
    [ "$output" = "modify mv" ]
}

@test "bash: abt help <TAB> lists the subcommands" {
    run complete_bash "abt help "
    [ "$output" = "cp doctor ls modify mv rm help" ]
    run complete_bash "abt help m"
    [ "$output" = "modify mv" ]
}

@test "bash: nothing is suggested after abt help <command>" {
    run complete_bash "abt help ls "
    [ "$output" = "" ]
}

@test "bash: arguments after the subcommand fall back to filename completion" {
    run complete_bash "abt ls fi"
    [ "$output" = "" ] # empty, so that bash's `-o default` filename completion takes over
    run bash -c 'source "${ABOUT_TRACKER_PATH}/completions/abt.sh" && complete -p abt'
    [ "$output" = "complete -o default -F _abt abt" ]
}

@test "zsh: sourcing registers the _abt completion for abt" {
    command -v zsh >/dev/null || skip "zsh is not installed"
    run zsh -f -c 'source "${ABOUT_TRACKER_PATH}/completions/abt.sh" && echo "${_comps[abt]}"'
    [ "$status" -eq 0 ]
    [ "$output" = "_abt" ]
}
