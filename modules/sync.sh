#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    declare_variables "$@"
    shift
    parse_arguments "$@"
    validate_arguments
    validate_terminal_width
    synchronize
}

declare_variables() {
    MODULE="$1"
    DIRECTION="$SYNC_DIRECTION"
    CHECK="$SYNC_CHECK"
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
    TERMINAL_WIDTH=$(tput cols)
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--direction)
                current_arg="$1"
                shift
                DIRECTION="${1:-}"
                [[ -z "$DIRECTION" ]] && { log_error "Option $current_arg requires a value"; show_usage; exit 1; }
                ;;
            -n|--no-check)
                CHECK="no"
                ;;
            *)
                log_error "Invalid option '$1'"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

show_usage() {
    echo "Usage: $APP_NAME_LOWER $MODULE [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                  Show help"
    echo "  -d, --direction VALUE       Use 'up' or 'down', default is 'up'"
    echo "  -n, --no-check              Synchronize without check (use at your own risk)"
}

validate_arguments() {
    validate_sync_direction_argument
    validate_sync_check_argument
}

validate_sync_direction_argument() {
    if [[ "$DIRECTION" != "up" ]] && [[ "$DIRECTION" != "down" ]]; then
        log_error "Invalid synchronization direction value '$DIRECTION'"
        show_usage
        return 1
    fi
}

validate_sync_check_argument() {
    if [[ "$CHECK" != "yes" ]] && [[ "$CHECK" != "no" ]]; then
        log_error "Invalid synchronization check value '$CHECK'"
        show_usage
        return 1
    fi
}

validate_terminal_width() {
    if [[ "$TERMINAL_WIDTH" -lt 100 ]]; then
        log_error "Terminal width is too small, please increase it to at least 100"
        return 1
    fi
}

synchronize() {
    for ((i = 0; i < ${#ROOT_DIRS[@]}; i++)); do
        local directory_pair="${ROOT_DIRS[$i]}"
        LOCAL_ROOT_DIR="$(echo "$directory_pair" | cut -d',' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        REMOTE_ROOT_DIR="$(echo "$directory_pair" | cut -d',' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        if [[ "$i" -gt 0 ]]; then echo ""; fi

        synchronize_with_single_directory_pair || return 1
    done
}

synchronize_with_single_directory_pair() {
    if [[ "$DIRECTION" == "up" ]]; then
        source "$APP_MODULES_DIR/sync/sync-up.sh" || return 1
    elif [[ "$DIRECTION" == "down" ]]; then
        source "$APP_MODULES_DIR/sync/sync-down.sh" || return 1
    fi
}

main "$@"
