#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    declare_variables "$@"
    shift
    parse_arguments "$@"
    validate_arguments

    if [[ "$BACKUP_ACTION" == "list" ]]; then
        list_backup
    elif [[ "$BACKUP_ACTION" == "delete" ]]; then
        delete_backup
    fi
}

declare_variables() {
    MODULE="$1"
    BACKUP_SOURCE="remote"
    BACKUP_PATH=""
    BACKUP_ACTION=""
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--delete)
                current_arg="$1"
                shift
                BACKUP_PATH="${1:-}"
                [[ -z "$BACKUP_PATH" ]] && { log_error "Option '$current_arg' requires a value."; show_usage; exit 1; }
                BACKUP_ACTION="delete"
                ;;
            -l|--list)
                BACKUP_ACTION="list"
                ;;
            -s|--source)
                current_arg="$1"
                shift
                BACKUP_SOURCE="${1:-}"
                [[ -z "$BACKUP_SOURCE" ]] && { log_error "Option '$current_arg' requires a value."; show_usage; exit 1; }
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
    echo "    -h, --help                Show help"
    echo "    -d, --delete VALUE        Delete backup file or directory"
    echo "    -l, --list                List backup files and directories"
    echo "    -s, --source VALUE        Location of backup files ('remote' or 'local', default is 'remote')"
}

validate_arguments() {
    validate_backup_action_argument
    validate_backup_source_argument
}

validate_backup_action_argument() {
    if [[ "$BACKUP_ACTION" != "delete" ]] && [[ "$BACKUP_ACTION" != "list" ]]; then
        log_error "Invalid action value. You must specify -d|--delete or -l|--list."
        show_usage
        return 1
    fi
}

validate_backup_source_argument() {
    if [[ "$BACKUP_SOURCE" != "remote" ]] && [[ "$BACKUP_SOURCE" != "local" ]]; then
        log_error "Invalid source value '$BACKUP_SOURCE'."
        show_usage
        return 1
    fi
}

list_backup() {
    if [[ "$BACKUP_SOURCE" == "remote" ]]; then
        list_backup_on_remote
    elif [[ "$BACKUP_SOURCE" == "local" ]]; then
        list_backup_on_local
    fi
}

list_backup_on_remote() {
    log_info "Listing backup at '$REMOTE_BACKUP_DIR'..."

    if rclone ls "$REMOTE_BACKUP_DIR" | sed 's/^\s*[^ ]*\s*//'; then
        log_ok "Listed backup at '$REMOTE_BACKUP_DIR' successfully."
    else
        log_failed "Listed backup at '$REMOTE_BACKUP_DIR' failed."
        return 1
    fi
}

list_backup_on_local() {
    log_info "Listing backup at '$LOCAL_BACKUP_DIR'..."

    if find "$LOCAL_BACKUP_DIR" -name '*' -type f -o -name '*' -type d | sort | sed "s|^$LOCAL_BACKUP_DIR||" | sed "s|^/||" | sed '/^[[:space:]]*$/d'; then
        log_ok "Listed backup at '$LOCAL_BACKUP_DIR' successfully."
    else
        log_failed "Listed backup at '$LOCAL_BACKUP_DIR' failed."
        return 1
    fi
}

delete_backup() {
    if [[ "$BACKUP_SOURCE" == "remote" ]]; then
        delete_backup_on_remote
    elif [[ "$BACKUP_SOURCE" == "local" ]]; then
        delete_backup_on_local
    fi
}

delete_backup_on_remote() {
    FULL_BACKUP_PATH="$REMOTE_BACKUP_DIR/$BACKUP_PATH"

    log_info "Deleting backup at '$FULL_BACKUP_PATH'..."

    check_if_backup_path_exists_on_remote || return 1
    confirm_to_delete || return 0

    if rclone purge "$FULL_BACKUP_PATH"; then
        log_ok "Deleted backup at '$FULL_BACKUP_PATH' successfully."
    else
        log_failed "Deleted backup at '$FULL_BACKUP_PATH' failed."
        return 1
    fi
}

check_if_backup_path_exists_on_remote() {
    log_info "Checking if backup path '$FULL_BACKUP_PATH' exists..."

    if ! rclone lsf "$FULL_BACKUP_PATH" >/dev/null 2>&1; then
        log_error "Backup path '$FULL_BACKUP_PATH' does not exist."
        return 1
    fi
}

delete_backup_on_local() {
    FULL_BACKUP_PATH="$LOCAL_BACKUP_DIR/$BACKUP_PATH"

    log_info "Deleting backup at '$FULL_BACKUP_PATH'..."

    check_if_backup_path_exists_on_local || return 1
    confirm_to_delete || return 0

    if rm -rf "$FULL_BACKUP_PATH"; then
        log_ok "Deleted backup at '$FULL_BACKUP_PATH' successfully."
    else
        log_failed "Deleted backup at '$FULL_BACKUP_PATH' failed."
        return 1
    fi
}

check_if_backup_path_exists_on_local() {
    log_info "Checking if backup path '$FULL_BACKUP_PATH' exists..."

    if [[ ! -d "$FULL_BACKUP_PATH" ]] && [[ ! -f "$FULL_BACKUP_PATH" ]]; then
        log_error "Backup path '$FULL_BACKUP_PATH' does not exist."
        return 1
    fi
}

confirm_to_delete() {
    read -p "Are you sure you want to delete this backup? (y/n) " confirmation
    if [[ "$confirmation" != "y" ]]; then
        log_info "Backup deletion cancelled by user."
        return 1
    fi
}

main "$@"
