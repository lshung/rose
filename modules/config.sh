#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    if util_check_rclone_remote_exists; then
        log_ok "Rclone remote '$REMOTE_NAME' is already configured."
        return 0
    fi

    configure_rclone_remote
}

configure_rclone_remote() {
    log_info "Configuring Rclone remote '$REMOTE_NAME'..."

    select_rclone_provider || return 1

    rclone config create "$REMOTE_NAME" "$SELECTED_PROVIDER"

    if [ $? -eq 0 ]; then
        log_ok "Configured Rclone remote '$REMOTE_NAME' with provider '$SELECTED_PROVIDER' successfully."
    else
        log_failed "Configured Rclone remote '$REMOTE_NAME' with provider '$SELECTED_PROVIDER' failed."
        return 1
    fi
}

select_rclone_provider() {
    if ! util_get_all_rclone_providers >/dev/null 2>&1; then
        log_error "Could not get supported Rclone providers."
        return 1
    fi

    log_info "Selecting Rclone provider..."

    local providers_list=($(util_get_all_rclone_providers))
    SELECTED_PROVIDER="$(util_select_from_list "${providers_list[@]}")"
}

main
