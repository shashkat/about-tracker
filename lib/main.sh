# This file doesn't need a shebang line as it is meant to be sourced and not executed as a script.
# This also means that all the code in this file should be shell-type (bash and zsh) agnostic.

# ensure that the env variable ABOUT_TRACKER_PATH is set. If not, exit
if [[ -z "${ABOUT_TRACKER_PATH}" ]]; then # -z checks if a variable is empty or unset
    echo "Error: ABOUT_TRACKER_PATH global variable is not set. Please define it in your .zshrc or .bashrc before running this script."
    exit 1
fi

# also not importing the functions.sh here. It is gonna be sourced in each file in bin, as that would 
# remove the requirement also making functions.sh shell-type agnostic.

# wrapper functions that run the relevant script as executable

about_modify() {
    ${ABOUT_TRACKER_PATH}/bin/about_modify.sh "$@"
}
ls() {
    ${ABOUT_TRACKER_PATH}/bin/ls.sh "$@"
}
cp() {
    ${ABOUT_TRACKER_PATH}/bin/cp.sh "$@"
}
mv() {
    ${ABOUT_TRACKER_PATH}/bin/mv.sh "$@"
}
rm() {
    ${ABOUT_TRACKER_PATH}/bin/rm.sh "$@"
}

