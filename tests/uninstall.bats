#!/usr/bin/env bats

# Tests for uninstall.sh. HOME is pointed at a throwaway directory for every test, so neither script ever touches
# the real ~/.zshrc, ~/.bashrc or ~/.local/share/about-tracker.

load test_helper

BLOCK_START="# >>> about-tracker >>>"

setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    INSTALL_DIR="${HOME}/.local/share/about-tracker"
}

run_install() {
    SHELL="$1" run bash "${REPO_ROOT}/install.sh"
}

run_uninstall() {
    run bash "${REPO_ROOT}/uninstall.sh"
}

@test "removes the install directory and the block, and keeps the rest of the init file" {
    printf 'export FOO=bar\nalias ll="ls -l"\n' > "${HOME}/.zshrc"
    run_install /bin/zsh
    run_uninstall
    [ "$status" -eq 0 ]
    [ ! -e "$INSTALL_DIR" ]
    [ -d "${HOME}/.local/share" ] # the shared parent directory is left alone
    [ "$(cat "${HOME}/.zshrc")" = $'export FOO=bar\nalias ll="ls -l"' ]
}

@test "init file that only had the block is left empty, not deleted" {
    run_install /bin/bash
    run_uninstall
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.bashrc" ]
    [ ! -s "${HOME}/.bashrc" ]
}

@test "removes the block from both .zshrc and .bashrc" {
    run_install /bin/zsh
    run_install /bin/bash
    run_uninstall
    [ "$status" -eq 0 ]
    ! grep -qF "$BLOCK_START" "${HOME}/.zshrc"
    ! grep -qF "$BLOCK_START" "${HOME}/.bashrc"
}

@test "running it when about-tracker is not installed succeeds and changes nothing" {
    printf 'export FOO=bar\n' > "${HOME}/.zshrc"
    run_uninstall
    [ "$status" -eq 0 ]
    [ "$(cat "${HOME}/.zshrc")" = "export FOO=bar" ]
    [ ! -e "${HOME}/.bashrc" ]
}

@test "a symlinked init file stays a symlink" {
    mkdir -p "${HOME}/dotfiles"
    printf 'export FOO=bar\n' > "${HOME}/dotfiles/zshrc"
    ln -s "${HOME}/dotfiles/zshrc" "${HOME}/.zshrc"
    run_install /bin/zsh
    [ -L "${HOME}/.zshrc" ] || skip "install.sh replaced the symlink, so there is nothing to check here"
    run_uninstall
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.zshrc" ]
    [ "$(cat "${HOME}/dotfiles/zshrc")" = "export FOO=bar" ]
}

@test "init file with a start marker but no end marker is left untouched" {
    printf '%s\nexport FOO=bar\n' "$BLOCK_START" > "${HOME}/.zshrc"
    before="$(cat "${HOME}/.zshrc")"
    run_uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Warning"*"no '# <<< about-tracker <<<'"* ]]
    [ "$(cat "${HOME}/.zshrc")" = "$before" ]
}

@test "warns about abt aliases left outside the block" {
    run_install /bin/zsh
    printf "alias ls='abt ls'\n# alias cp='abt cp'\nexport RABBIT=1\n" >> "${HOME}/.zshrc"
    run_uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"line 6:alias ls='abt ls'"* ]]
    [[ "$output" != *"alias cp"* ]] # commented out, so harmless
    [[ "$output" != *"RABBIT"* ]]
}

@test "works when run from the installed copy itself" {
    run_install /bin/zsh
    run bash "${INSTALL_DIR}/uninstall.sh"
    [ "$status" -eq 0 ]
    [ ! -e "$INSTALL_DIR" ]
    [[ "$output" == *"about-tracker uninstalled."* ]]
}
