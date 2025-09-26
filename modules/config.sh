#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    if util_check_rclone_remote_exists; then
        log_ok "Rclone remote '$REMOTE_NAME' is already configured."
    else
        configure_onedrive
    fi
}

configure_onedrive() {
    log_info "Configuring Rclone remote '$REMOTE_NAME'..."

    rclone config create "$REMOTE_NAME" onedrive

    if [ $? -eq 0 ]; then
        log_ok "Configured Rclone remote '$REMOTE_NAME' successfully."
    else
        log_failed "Configured Rclone remote '$REMOTE_NAME' failed."
        return 1
    fi
}

main
