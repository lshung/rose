#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31mERR\033[0m] This script cannot be executed directly" 1>&2; exit 1; }

# Exit on error
set -e

util_is_check_report_not_empty() {
    [ -s "$CHECK_REPORT_FILE" ] && return 0 || return 1
}
