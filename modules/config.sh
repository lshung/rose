#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    if util_check_rclone_remote_exists; then
        log_ok "Rclone remote '$REMOTE_NAME' is already configured."
    else
        configure_onedrive
    fi
}

configure_onedrive() {
    rclone config create "$REMOTE_NAME" onedrive

    if [ $? -eq 0 ]; then
        log_ok "OneDrive configuration completed successfully!"
    else
        log_failed "Configuration failed. Please check your internet connection and try again."
        return 1
    fi
}

main
