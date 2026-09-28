#!/usr/bin/env bats

# Tests for install.sh. HOME is pointed at a throwaway directory for every test, so the installer never touches
# the real ~/.zshrc, ~/.bashrc or ~/.local/share/about-tracker.

load test_helper

BLOCK_START="# >>> about-tracker >>>"

setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    INSTALL_DIR="${HOME}/.local/share/about-tracker"
}

# Run install.sh as if the user's login shell was $1 (e.g. /bin/zsh or /bin/bash)
run_install() {
    SHELL="$1" run bash "${REPO_ROOT}/install.sh"
}

@test "copies the package into ~/.local/share/about-tracker with executable scripts" {
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    [ -x "${INSTALL_DIR}/bin/abt" ]
    [ -f "${INSTALL_DIR}/lib/functions.sh" ]
    for script in ls cp mv rm modify; do
        [ -x "${INSTALL_DIR}/libexec/${script}.sh" ]
    done
}

@test "zsh user: block is added to .zshrc and .bashrc is left alone" {
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    grep -qF "$BLOCK_START" "${HOME}/.zshrc"
    [ ! -e "${HOME}/.bashrc" ]
}

@test "bash user: block is added to .bashrc and .zshrc is left alone" {
    run_install /bin/bash
    [ "$status" -eq 0 ]
    grep -qF "$BLOCK_START" "${HOME}/.bashrc"
    [ ! -e "${HOME}/.zshrc" ]
}

@test "existing content of the shell init file is preserved" {
    printf 'export FOO=bar\nalias ll="ls -l"\n' > "${HOME}/.zshrc"
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    grep -qxF 'export FOO=bar' "${HOME}/.zshrc"
    grep -qxF 'alias ll="ls -l"' "${HOME}/.zshrc"
}

@test "last line of a shell init file without trailing newline is not merged with the block" {
    printf 'export FOO=bar' > "${HOME}/.zshrc" # no trailing newline
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    grep -qxF 'export FOO=bar' "${HOME}/.zshrc"
    grep -qxF "$BLOCK_START" "${HOME}/.zshrc"
}

@test "installing twice leaves exactly one block in the shell init file" {
    run_install /bin/zsh
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    [ "$(grep -cF "$BLOCK_START" "${HOME}/.zshrc")" -eq 1 ]
}

@test "reinstalling replaces the old install directory" {
    run_install /bin/zsh
    touch "${INSTALL_DIR}/stale_file"
    run_install /bin/zsh
    [ "$status" -eq 0 ]
    [ ! -e "${INSTALL_DIR}/stale_file" ]
}

@test "after sourcing the init file, abt resolves to the installed copy and runs" {
    run_install /bin/bash
    # env -i gives a clean environment, like a brand new shell that only has what .bashrc sets up
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" bash -c 'source "$HOME/.bashrc" && command -v abt && abt help'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "${INSTALL_DIR}/bin/abt" ]
    [ "${lines[1]}" = "Usage: abt <command> [args...]" ]
}
