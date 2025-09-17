#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

main() {
    create_log_dir_if_not_exists
    create_local_root_dir_if_not_exists
    create_symlink_to_this_app_if_not_exists
    install_rclone_if_not_installed
    util_clean_up_log_files

    if [[ "$1" != "-c" ]] && [[ "$1" != "--config" ]]; then
        show_warning_if_rclone_remote_is_not_configured
    fi
}

create_log_dir_if_not_exists() {
    [ -d "$LOG_DIR" ] && return 0
    mkdir -p "$LOG_DIR"
    log_ok "Log directory created successfully!"
}

create_local_root_dir_if_not_exists() {
    [ -d "$LOCAL_ROOT_DIR" ] && return 0

    log_info "Creating local root directory: $LOCAL_ROOT_DIR"

    if mkdir -p "$LOCAL_ROOT_DIR"; then
        log_ok "Local root directory created successfully!"
    else
        log_failed "Failed to create local root directory."
        return 1
    fi
}

create_symlink_to_this_app_if_not_exists() {
    local app_symlink_path="$HOME/.local/bin/$APP_NAME_LOWER"

    [ -f "$app_symlink_path" ] && return 0

    log_info "Creating symlink to this app: $app_symlink_path"

    if ln -sf "$APP_DIR"/run "$app_symlink_path"; then
        log_ok "Symlink created successfully!"
    else
        log_failed "Failed to create symlink."
        return 1
    fi

}

install_rclone_if_not_installed() {
    util_check_rclone_installed && return 0

    log_info "Installing Rclone"

    if util_install_rclone; then
        log_ok "Rclone installed successfully!"
    else
        log_failed "Failed to install Rclone."
        return 1
    fi
}

show_warning_if_rclone_remote_is_not_configured() {
    if ! util_check_rclone_remote_exists; then
        log_warning "Rclone remote '$REMOTE_NAME' is not configured."
        log_warning "Please run: 'rose --config' to configure it."
        return 1
    fi
}

main "$@"
