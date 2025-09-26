#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    declare_variables "$@"
    shift
    parse_arguments "$@"
}

declare_variables() {
    MODULE="$1"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dir)
                show_log_directory
                exit 0
                ;;
            -l|--last)
                view_last_log_file
                exit 0
                ;;
            -r|--remove)
                remove_all_log_files
                exit 0
                ;;
            *)
                log_error "Invalid option '$1'."
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
    echo "    -h, --help        Show help"
    echo "    -d, --dir         Show the log directory path"
    echo "    -l, --last        View the last log file"
    echo "    -r, --remove      Remove all log files"
}

show_log_directory() {
    log_info "The log directory is located at '$LOG_DIR'."
}

view_last_log_file() {
    local last_log_file=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -n 1)

    if [ -z "$last_log_file" ]; then
        log_error "No log files found in '$LOG_DIR'."
        return 1
    fi

    cat "$last_log_file"
}

remove_all_log_files() {
    rm -f "$LOG_DIR"/*.log
}

main "$@"
