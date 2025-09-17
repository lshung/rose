#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    install_rclone_if_not_installed
    check_remote_exists || configure_onedrive
}

install_rclone_if_not_installed() {
    if ! command -v rclone >/dev/null 2>&1; then
        sudo pacman -S rclone --noconfirm
    fi
}

check_remote_exists() {
    if rclone listremotes | grep -q "^$REMOTE_NAME:$"; then
        echo "Rclone remote '$REMOTE_NAME' is already configured."
    else
        return 1
    fi
}

configure_onedrive() {
    rclone config create "$REMOTE_NAME" onedrive

    if [ $? -eq 0 ]; then
        echo "OneDrive configuration completed successfully!"
    else
        echo "Configuration failed. Please check your internet connection and try again." 1>&2
        return 1
    fi
}

main
