#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    test_connection
}

test_connection() {
    log_info "Testing connection to Rclone remote '$REMOTE_NAME'..."

    if rclone lsd "$REMOTE_NAME:"; then
        log_ok "Tested connection successfully."
    else
        log_failed "Tested connection failed."
        return 1
    fi
}

main
