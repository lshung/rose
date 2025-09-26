#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

util_concatenate_filter_rules() {
    mkdir -p "$(dirname "$FILTER_RULES_FILE")"

    cat "$APP_FILTER_RULES_FILE" > "$FILTER_RULES_FILE"

    if [ -r "$APP_CONFIG_FILTER_RULES_FILE" ]; then
        cat "$APP_CONFIG_FILTER_RULES_FILE" >> "$FILTER_RULES_FILE"
    fi
}
