# Shared setup for all .bats files. Load it at the top of a test file with `load test_helper`.

# Point ABOUT_TRACKER_PATH at this repo (the directory above tests/), so that the tests always run against the
# working tree and never against an installed copy in ~/.local/share/about-tracker.
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
export ABOUT_TRACKER_PATH="$REPO_ROOT"
export PATH="${REPO_ROOT}/bin:${PATH}" # makes the abt command available

source "${REPO_ROOT}/lib/functions.sh" # for the helper functions and the color variables used in expected outputs

# Copy the read-only fixtures into a fresh directory and cd into it. BATS_TEST_TMPDIR is unique to each test and
# deleted by bats afterwards, so tests can freely create/move/delete files without any manual cleanup, and a
# failing test can never leave the fixtures in a dirty state for the tests after it.
setup_fixtures() {
    WORK_DIR="${BATS_TEST_TMPDIR}/work"
    command cp -R "${REPO_ROOT}/tests/fixtures" "$WORK_DIR"
    cd "$WORK_DIR" || return 1
}
