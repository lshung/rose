#!/bin/bash

# Exit if this script is being executed directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

util_select_from_list() {
    local -a options=("$@")
    PS3="-//- Enter your choice from the list above (1-${#options[@]}): "
    select opt in "${options[@]}"; do
        if (( ${REPLY} >= 1 )) && (( ${REPLY} <= ${#options[@]} )); then
            echo "$opt"
            break
        fi
    done
}
