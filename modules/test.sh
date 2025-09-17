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
        echo "Connection test successful!"
    else
        echo "Connection test failed. Please check your configuration." 1>&2
        return 1
    fi
}

main
