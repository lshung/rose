#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    declare_variables
    synchronize
}

declare_variables() {
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
}

synchronize() {
    log_info "Synchronizing from remote to local: $REMOTE_ROOT_DIR -> $LOCAL_ROOT_DIR"
    log_info "Local backup directory: $LOCAL_BACKUP_DIR/$TIMESTAMP"

    if [ "$CHECK" = "yes" ]; then
        run_check_before_synchronization
        confirm_to_synchronize || return 1
    fi

    execute_real_synchronization
}

run_check_before_synchronization() {
    log_info "Starting rclone check"
    log_warning "This may take a while, please wait patiently."

    rclone check "$REMOTE_ROOT_DIR" "$LOCAL_ROOT_DIR" --filter-from="$FILTER_RULES_FILE" --combined "$CHECK_REPORT_FILE" >/dev/null 2>&1 || true
    cat "$CHECK_REPORT_FILE" | sort > "$CHECK_REPORT_FILE.sorted"
    mv "$CHECK_REPORT_FILE.sorted" "$CHECK_REPORT_FILE"

    log_warning "Please review the report carefully before confirmation."
}

confirm_to_synchronize() {
    read -p "Do you want to continue to synchronize from remote to local? (y/n) " confirmation
    if [[ "$confirmation" != "y" ]]; then
        log_info "Synchronization cancelled by user."
        return 1
    fi
}

execute_real_synchronization() {
    local flags="--verbose --checksum --backup-dir=$LOCAL_BACKUP_DIR/$TIMESTAMP --filter-from=$FILTER_RULES_FILE"

    log_info "Starting live synchronization"

    if rclone sync "$REMOTE_ROOT_DIR" "$LOCAL_ROOT_DIR" $flags > >(tee -a "$LOG_FILE") 2>&1; then
        log_ok "Live synchronization completed."
    else
        log_failed "Live synchronization failed. Check log file: $LOG_FILE for details."
        return 1
    fi
}

main
