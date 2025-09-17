#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    test_connection
}

test_connection() {
    if rclone lsd "$REMOTE_NAME:"; then
        log_ok "Connection test successful!"
    else
        log_failed "Connection test failed. Please check your configuration."
        return 1
    fi
}

main
