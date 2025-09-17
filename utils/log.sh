#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

NC='\033[0m'        # Reset color
RED='\033[0;31m'    # Red
GREEN='\033[0;32m'  # Green
YELLOW='\033[0;33m' # Yellow

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            level_text=" INFO "
            echo "[$timestamp] [${level_text}] $message" | tee -a "$LOG_FILE"
            ;;
        "WARNING")
            level_color="$YELLOW"
            level_text=" WARN "
            echo -e "[$timestamp] [${level_color}${level_text}${NC}] $message" | tee -a "$LOG_FILE" 1>&2
            ;;
        "ERROR")
            level_color="$RED"
            level_text=" ERRO "
            echo -e "[$timestamp] [${level_color}${level_text}${NC}] $message" | tee -a "$LOG_FILE" 1>&2
            ;;
        "OK")
            level_color="$GREEN"
            level_text="  OK  "
            echo -e "[$timestamp] [${level_color}${level_text}${NC}] $message" | tee -a "$LOG_FILE"
            ;;
        "FAILED")
            level_color="$RED"
            level_text="FAILED"
            echo -e "[$timestamp] [${level_color}${level_text}${NC}] $message" | tee -a "$LOG_FILE" 1>&2
            ;;
    esac
}

log_info() {
    log_message "INFO" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_ok() {
    log_message "OK" "$1"
}

log_failed() {
    log_message "FAILED" "$1"
}

util_clean_up_log_files() {
    local log_files_list=($(find "$LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2-))
    local log_files_count=${#log_files_list[@]}

    if [[ $log_files_count -gt $LOG_FILE_COUNT ]]; then
        for ((i = LOG_FILE_COUNT; i < log_files_count; i++)); do
            [ -f "${log_files_list[$i]}" ] && rm -f "${log_files_list[$i]}"
        done
    fi
}
