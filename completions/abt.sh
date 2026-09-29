# Tab completion for the abt command, in both bash and zsh. This file is sourced (not executed) from the
# about-tracker block that install.sh adds to .bashrc/.zshrc.
#
# `abt <TAB>` lists the subcommands, `abt l<TAB>` fills in `abt ls`, and `abt m<TAB>` lists `modify` and `mv`.
# `abt help <TAB>` lists the subcommands again, since help takes a command name. After any other subcommand, TAB
# completes file and directory names as usual.

# Prints the subcommand names, one per line. They are read from the scripts in libexec, so a new libexec/<name>.sh
# shows up in the completions without any change to this file.
_abt_subcommands() {
    local script
    [[ -d "${ABOUT_TRACKER_PATH}/libexec" ]] || return 0
    for script in "${ABOUT_TRACKER_PATH}"/libexec/*.sh; do
        [[ -f "$script" ]] || continue
        script="${script##*/}"   # strip the directory part
        echo "${script%.sh}"     # strip the .sh extension
    done
    echo "help"
}

if [[ -n "$ZSH_VERSION" ]]; then
    # compdef comes from zsh's completion system. Frameworks like oh-my-zsh already load it, but a plain .zshrc
    # might not, in which case we load it here.
    if ! whence compdef >/dev/null 2>&1; then
        autoload -Uz compinit && compinit
    fi

    _abt() {
        local -a subcommands
        subcommands=( ${(f)"$(_abt_subcommands)"} ) # (f) splits the output into an array on newlines
        if (( CURRENT == 2 )); then # the word being completed is the subcommand
            compadd -a subcommands
        elif [[ "${words[2]}" == "help" ]]; then
            (( CURRENT == 3 )) && compadd -a subcommands # help takes one command name and nothing after it
        else
            _files
        fi
    }
    compdef _abt abt

elif [[ -n "$BASH_VERSION" ]]; then
    _abt() {
        local cur="${COMP_WORDS[COMP_CWORD]}" # the word being completed
        COMPREPLY=()
        if [[ $COMP_CWORD -eq 1 ]]; then # the word being completed is the subcommand
            # compgen -W prints the words from the list that start with $cur
            COMPREPLY=( $(compgen -W "$(_abt_subcommands)" -- "$cur") )
        elif [[ "${COMP_WORDS[1]}" == "help" ]]; then
            # help takes one command name and nothing after it
            [[ $COMP_CWORD -eq 2 ]] && COMPREPLY=( $(compgen -W "$(_abt_subcommands)" -- "$cur") )
            # compopt (bash 4+) turns off the filename fallback for this TAB press, so that no file names are
            # suggested even when nothing above matched. The bash 3.2 that ships with macOS doesn't have it.
            type compopt >/dev/null 2>&1 && compopt +o default
        fi
        # When COMPREPLY is left empty, `-o default` below makes bash fall back to its normal filename completion.
    }
    complete -o default -F _abt abt
fi
