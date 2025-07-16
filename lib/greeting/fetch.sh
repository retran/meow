#!/usr/bin/env bash

# lib/greeting/fetch.sh - Functions for fetching system information for greeting

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_FETCH_SOURCED:-}" ]]; then
    return 0
fi
_LIB_GREETING_FETCH_SOURCED=1

get_system_info() {
    DATE_FULL=$(date +"%A, %B %d, %Y")
    TIME_CURRENT=$(date +"%H:%M:%S")
    OS_INFO=$(uname -srm)
    UPTIME_INFO=$(uptime | sed -E 's/^.*up *//; s/, *[0-9]+ user.*//; s/, *load average.*//; s/^[ \\t]*//; s/[ \\t]*$//')
    HOME_DISK_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4 "B free / " $5 " used"}')

    if [[ "$OSTYPE" == "darwin"* ]]; then
        RAM_STATS=$(top -l 1 -n 0 | grep PhysMem: | awk '{print $2 " used, " $6 " unused"}')
    fi

    if command -v brew >/dev/null 2>&1; then
        local brew_cache_file="${CACHE_DIR}/brew_outdated"
        if [[ -f "$brew_cache_file" && $(($(date +%s) - $(stat -f %m "$brew_cache_file" 2>/dev/null || stat -c %Y "$brew_cache_file" 2>/dev/null))) -lt 600 ]]; then
            OUTDATED_PACKAGES=$(cat "$brew_cache_file")
        else
            OUTDATED_PACKAGES="0"
            echo "$OUTDATED_PACKAGES" >"$brew_cache_file"
        fi
    fi

    HOUR_OF_DAY=$(date +"%H")
    HOUR_NUM=$((10#$HOUR_OF_DAY))
}

# New function that returns system info as structured data
get_system_info_structured() {
    local date_full time_current os_info uptime_info home_disk_space ram_stats outdated_packages hour_num
    
    date_full=$(date +"%A, %B %d, %Y")
    time_current=$(date +"%H:%M:%S")
    os_info=$(uname -srm)
    uptime_info=$(uptime | sed -E 's/^.*up *//; s/, *[0-9]+ user.*//; s/, *load average.*//; s/^[ \\t]*//; s/[ \\t]*$//')
    home_disk_space=$(df -h "$HOME" | awk 'NR==2 {print $4 "B free / " $5 " used"}')
    ram_stats=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ram_stats=$(top -l 1 -n 0 | grep PhysMem: | awk '{print $2 " used, " $6 " unused"}')
    fi
    
    outdated_packages="0"
    if command -v brew >/dev/null 2>&1; then
        local brew_cache_file="${CACHE_DIR}/brew_outdated"
        if [[ -f "$brew_cache_file" && $(($(date +%s) - $(stat -f %m "$brew_cache_file" 2>/dev/null || stat -c %Y "$brew_cache_file" 2>/dev/null))) -lt 600 ]]; then
            outdated_packages=$(cat "$brew_cache_file")
        else
            echo "$outdated_packages" >"$brew_cache_file"
        fi
    fi
    
    hour_num=$((10#$(date +"%H")))
    
    # Return as key=value pairs
    cat <<EOF
DATE_FULL=${date_full}
TIME_CURRENT=${time_current}
OS_INFO=${os_info}
UPTIME_INFO=${uptime_info}
HOME_DISK_SPACE=${home_disk_space}
RAM_STATS=${ram_stats}
OUTDATED_PACKAGES=${outdated_packages}
HOUR_NUM=${hour_num}
EOF
}
