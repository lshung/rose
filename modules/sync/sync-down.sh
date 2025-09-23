#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    log_info "Synchronizing from remote to local: $REMOTE_ROOT_DIR -> $LOCAL_ROOT_DIR"
    log_info "Local backup directory: $LOCAL_BACKUP_DIR/$TIMESTAMP"

    if [ "$CHECK" = "yes" ]; then
        run_check_before_synchronization || return 1
        util_is_check_report_not_empty || { log_info "Check report is empty, no need to synchronize."; return 0; }
        generate_custom_check_report || return 1
        confirm_to_synchronize || return 0
    fi

    execute_real_synchronization
}

run_check_before_synchronization() {
    log_info "Starting rclone check"
    log_warning "This may take a while, please wait patiently."

    rm -f "$CHECK_REPORT_FILE"
    rclone check "$REMOTE_ROOT_DIR" "$LOCAL_ROOT_DIR" --filter-from="$FILTER_RULES_FILE" --combined "$CHECK_REPORT_FILE" >/dev/null 2>&1 || true

    if [ ! -f "$CHECK_REPORT_FILE" ]; then
        log_error "There was an error when running 'rclone check'."
        return 1
    fi

    cat "$CHECK_REPORT_FILE" | sort > "$CHECK_REPORT_FILE.sorted"
    mv "$CHECK_REPORT_FILE.sorted" "$CHECK_REPORT_FILE"

    if [[ "$CHECK_REPORT_REMOVE_IDENTICAL" == "yes" ]]; then
        remove_identical_paths_from_check_report_file
    fi
}

remove_identical_paths_from_check_report_file() {
    grep -v '^=' "$CHECK_REPORT_FILE" > "$CHECK_REPORT_FILE.filtered"
    mv "$CHECK_REPORT_FILE.filtered" "$CHECK_REPORT_FILE"
}

generate_custom_check_report() {
    log_info "Generating custom check report"

    if ! python3 "$APP_MODULES_DIR/sync/check-report.py" "down" "$CHECK_REPORT_FILE" "$TERMINAL_WIDTH" > >(tee -a "$LOG_FILE") 2>&1; then
        log_error "Could not generate custom check report"
        return 1
    fi
}

confirm_to_synchronize() {
    log_warning "Please review the report carefully before confirmation."
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
