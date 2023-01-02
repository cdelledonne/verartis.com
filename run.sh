#!/usr/bin/env bash

# Script constants
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Error codes
ERROR_NONE=0
ERROR_MISSING_SUBCOMMAND=1
ERROR_INVALID_SUBCOMMAND=2
ERROR_MISSING_TARGET=3
ERROR_MISSING_DEST=4
ERROR_MISSING_THEME=5
ERROR_THEME_NOT_PATH=6
ERROR_INVALID_OPTION=7

################################################################################

echo_usage () {
    echo "Manage Hugo website."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} <subcommand>"
    echo ""
    echo "Subcommands:"
    echo "  serve           start local server"
    echo "  deploy          build and deploy website to remote server"
    echo "  set-dest        set destination host:path for deployment"
    echo "  update-modules  update Hugo modules"
    echo "  remove-theme    remove theme submodule"
    echo "  help            show this help message"
    echo ""
    echo "Run '${SCRIPT_NAME} help <subcommand>' to get help for a subcommand."
}

echo_usage_serve () {
    echo "Start local server."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} serve [options]"
    echo ""
    echo "Options:"
    echo "  -b, --bind <address>  bind local server to non-default address"
}

echo_usage_deploy () {
    echo "Build and deploy website to remote server."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} deploy [<host>:<path>]"
    echo ""
    echo "Options:"
    echo "  <host>:<path>  target host and destination path to deploy to"
}

echo_usage_set_dest () {
    echo "Set destination host:path for deployment."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} set-dest <host>:<path>"
    echo ""
    echo "Options:"
    echo "  <host>:<path>  target host and destination path to deploy to"
}

echo_usage_update_modules () {
    echo "Update Hugo modules."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} update-modules"
}

echo_usage_remove_theme () {
    echo "Remove theme submodule."
    echo ""
    echo "Usage:"
    echo "  ${SCRIPT_NAME} remove-theme <theme>"
    echo ""
    echo "Options:"
    echo "  <theme>  relative path to theme to remove"
}

################################################################################

set_env_var () {
    touch "${SCRIPT_DIR}/.env"

    local varname="$1"
    local varvalue="$2"
    local varexists=$(grep -cE "^${varname}=.*" "${SCRIPT_DIR}/.env")

    if [ "$varexists" -gt 0 ] ; then
        sed -i "s;^\(${varname}=\).*;\1${varvalue};" "${SCRIPT_DIR}/.env"
    else
        echo "${varname}=${varvalue}" >> "${SCRIPT_DIR}/.env"
    fi
}

log () {
    case "$1" in
        INFO) echo -n -e '\033[0;32mINFO:  \033[0m' ;;
        WARN) echo -n -e '\033[0;33mWARN:  \033[0m' >&2 ;;
        ERROR) echo -n -e '\033[0;31mERROR: \033[0m' >&2 ;;
        *) ;;
    esac
    echo "$2"
}

exit_error () {
    case $1 in
        $ERROR_MISSING_SUBCOMMAND)
            log ERROR "Missing subcommand." ;
            ;;
        $ERROR_INVALID_SUBCOMMAND)
            log ERROR "Invalid subcommand." ;
            ;;
        $ERROR_MISSING_TARGET)
            log ERROR "Target host and destination path not set." ;
            ;;
        $ERROR_MISSING_DEST)
            log ERROR "Must pass destination host:path for deployment." ;
            ;;
        $ERROR_MISSING_THEME)
            log ERROR "Must pass path to theme to remove." ;
            ;;
        $ERROR_THEME_NOT_PATH)
            log ERROR "Theme is not a valid path." ;
            ;;
        $ERROR_INVALID_OPTION)
            log ERROR "Invalid option." ;
            ;;
        *) ;;
    esac
    log INFO "Try '${SCRIPT_NAME} help' for more information." ;
    exit $1
}

################################################################################

serve () {
    declare -a options=()
    local bind_addr

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -b|--bind) bind_addr="$2" ; shift ; shift ;;
            *) exit_error $ERROR_INVALID_OPTION ;;
        esac
    done

    if [ ! -z "$bind_addr" ] ; then
        options+=("--bind" "${bind_addr}" "--baseURL" "http://${bind_addr}")
    fi

    log INFO "Starting local server"
    hugo serve "${options[@]}"
}

deploy () {
    if [ $# -gt 0 ] ; then
        local dest="$1"
    else
        if [ -z "$WEBSITE_DEPLOY_DEST" ] ; then
            exit_error $ERROR_MISSING_TARGET
        else
            dest="$WEBSITE_DEPLOY_DEST"
        fi
    fi

    local source_dir="${SCRIPT_DIR}/public"
    local source_files="${source_dir}/"

    log INFO "Removing old build"
    rm -rf "${source_dir}"

    log INFO "Building website"
    hugo --gc

    log INFO "Removing Workbox script"
    rm -f "${source_dir}"/service-worker.js

    log INFO "Deploying website to server"
    rsync \
        --recursive \
        --delete \
        --perms \
        --progress \
        --prune-empty-dirs \
        --times \
        --omit-dir-times \
        --verbose \
        "${source_files}" \
        "${dest}"
}

set_dest () {
    if [ $# -eq 0 ] ; then
        exit_error $ERROR_MISSING_DEST
    fi

    log INFO "Setting destination host:path for deployment"
    set_env_var "WEBSITE_DEPLOY_DEST" "$1"
}

update_modules () {
    log INFO "Updating Hugo modules"
    hugo mod clean
    hugo mod get -u
    hugo mod tidy
}

remove_theme () {
    if [ $# -eq 0 ] ; then
        exit_error $ERROR_MISSING_THEME
    fi

    local theme="$1"
    if [ ! -d "$theme" ] ; then
        exit_error $ERROR_THEME_NOT_PATH
    fi

    log INFO "Removing theme submodule"
    # From https://stackoverflow.com/a/1260982/13297923
    git rm "$theme"
    rm -rf ".git/modules/${theme}"
    git config --remove-section "submodule.${theme}"
}

help () {
    if [ $# -eq 0 ] ; then
        echo_usage
        return
    fi

    case "$1" in
        "serve") echo_usage_serve ;;
        "deploy") echo_usage_deploy ;;
        "set-dest") echo_usage_set_dest ;;
        "update-modules") echo_usage_update_modules ;;
        "remove-theme") echo_usage_remove_theme ;;
        *) exit_error $ERROR_INVALID_SUBCOMMAND ;;
    esac
}

################################################################################

main () {
    if [ $# -eq 0 ] ; then
        exit_error $ERROR_MISSING_SUBCOMMAND
    fi

    # Load environment variables
    if [ -f "${SCRIPT_DIR}/.env" ] ; then
        source "${SCRIPT_DIR}/.env"
    fi

    # Dispatch subcommand
    case "$1" in
        "serve") shift ; serve "$@" ;;
        "deploy") shift ; deploy "$@" ;;
        "set-dest") shift ; set_dest "$@" ;;
        "update-modules") shift ; update_modules "$@" ;;
        "remove-theme") shift ; remove_theme "$@" ;;
        "help") shift ; help "$@" ;;
        *) exit_error $ERROR_INVALID_SUBCOMMAND ;;
    esac

    exit $ERROR_NONE
}

main "$@"
