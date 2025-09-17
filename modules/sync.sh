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
    synchronize
}

declare_variables() {
    MODULE="$1"
    DIRECTION="$SYNC_DIRECTION"
    DRY_RUN="$SYNC_DRY_RUN"
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
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
            -n|--no-dry-run)
                DRY_RUN="no"
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
    echo "  -n, --no-dry-run            Synchronize without dry-run (use at your own risk)"
}

validate_arguments() {
    validate_sync_direction_argument
    validate_sync_dry_run_argument
}

validate_sync_direction_argument() {
    if [[ "$DIRECTION" != "up" ]] && [[ "$DIRECTION" != "down" ]]; then
        log_error "Invalid synchronization direction value '$DIRECTION'"
        show_usage
        return 1
    fi
}

validate_sync_dry_run_argument() {
    if [[ "$DRY_RUN" != "yes" ]] && [[ "$DRY_RUN" != "no" ]]; then
        log_error "Invalid synchronization dry-run value '$DRY_RUN'"
        show_usage
        return 1
    fi
}

synchronize() {
    if [[ "$DIRECTION" == "up" ]]; then
        synchronize_from_local_to_remote
    elif [[ "$DIRECTION" == "down" ]]; then
        synchronize_from_remote_to_local
    fi
}

synchronize_from_local_to_remote() {
    log_info "Synchonizing from local to remote: $LOCAL_ROOT_DIR -> $REMOTE_ROOT_DIR"
    log_info "Remote backup directory: $REMOTE_BACKUP_DIR/$TIMESTAMP"

    if [ "$DRY_RUN" = "yes" ]; then
        simulate_synchronization_from_local_to_remote
        read -p "Do you want to continue to synchronize from local to remote? (y/n) " confirmation
        if [ "$confirmation" != "y" ]; then
            log_ok "Synchronization cancelled by user."
            return 1
        fi
    fi

    execute_synchronization_from_local_to_remote
}

simulate_synchronization_from_local_to_remote() {
    local flags="--verbose --checksum --backup-dir=$REMOTE_BACKUP_DIR/$TIMESTAMP --dry-run"

    log_info "Starting dry-run synchronization"

    if rclone sync "$LOCAL_ROOT_DIR" "$REMOTE_ROOT_DIR" $flags > >(tee -a "$LOG_FILE") 2>&1; then
        log_ok "Dry-run synchronization completed."
        log_warning "Please re-check carefully before confirmation."
    else
        log_failed "Dry-run synchronization failed. Check log file: $LOG_FILE for details."
        return 1
    fi
}

execute_synchronization_from_local_to_remote() {
    local flags="--verbose --checksum --backup-dir=$REMOTE_BACKUP_DIR/$TIMESTAMP"

    log_info "Starting live synchronization"

    if rclone sync "$LOCAL_ROOT_DIR" "$REMOTE_ROOT_DIR" $flags > >(tee -a "$LOG_FILE") 2>&1; then
        log_ok "Live synchronization completed."
    else
        log_failed "Live synchronization failed. Check log file: $LOG_FILE for details."
        return 1
    fi
}

synchronize_from_remote_to_local() {
    log_info "Synchronizing from remote to local: $REMOTE_ROOT_DIR -> $LOCAL_ROOT_DIR"
    log_info "Local backup directory: $LOCAL_BACKUP_DIR/$TIMESTAMP"

    if [ "$DRY_RUN" = "yes" ]; then
        simulate_synchronization_from_remote_to_local
        read -p "Do you want to continue to synchronize from remote to local? (y/n) " confirmation
        if [ "$confirmation" != "y" ]; then
            log_ok "Synchronization cancelled by user."
            return 1
        fi
    fi

    execute_synchronization_from_remote_to_local
}

simulate_synchronization_from_remote_to_local() {
    local flags="--verbose --checksum --backup-dir=$LOCAL_BACKUP_DIR/$TIMESTAMP --dry-run"

    log_info "Starting dry-run synchronization"

    if rclone sync "$REMOTE_ROOT_DIR" "$LOCAL_ROOT_DIR" $flags > >(tee -a "$LOG_FILE") 2>&1; then
        log_ok "Dry-run synchronization completed."
        log_warning "Please re-check carefully before confirmation."
    else
        log_failed "Dry-run synchronization failed. Check log file: $LOG_FILE for details."
        return 1
    fi
}

execute_synchronization_from_remote_to_local() {
    local flags="--verbose --checksum --backup-dir=$LOCAL_BACKUP_DIR/$TIMESTAMP"

    log_info "Starting live synchronization"

    if rclone sync "$REMOTE_ROOT_DIR" "$LOCAL_ROOT_DIR" $flags > >(tee -a "$LOG_FILE") 2>&1; then
        log_ok "Live synchronization completed."
    else
        log_failed "Live synchronization failed. Check log file: $LOG_FILE for details."
        return 1
    fi
}

main "$@"
