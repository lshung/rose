#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

util_check_rclone_installed() {
    command -v rclone >/dev/null 2>&1
}

util_install_rclone() {
    sudo pacman -S rclone --noconfirm >/dev/null
}

util_check_rclone_remote_exists() {
    rclone listremotes 2>/dev/null | grep -q "^$REMOTE_NAME:$"
}
