#!/usr/bin/env bash

# lib/motd/motd.sh - Message of the Day (MOTD) display system

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_MOTD_SOURCED:-}" ]]; then
  return 0
fi
_LIB_MOTD_SOURCED=1

if [[ -z "$DOTFILES_DIR" ]]; then
    echo "Error: DOTFILES_DIR environment variable is not set." >&2
    return 1
fi

readonly MOTD_ASSETS_DIR="${DOTFILES_DIR}/assets"
readonly MOTD_CACHE_DIR="${HOME}/.cache/shell-motd"
readonly MOTD_ASCII_ART_FILE="${MOTD_ASSETS_DIR}/ascii/motd.ascii"

mkdir -p "${MOTD_CACHE_DIR}"

source "${DOTFILES_DIR}/lib/core/colors.sh"

# Loads comments from a specific section of a YAML file.
load_yaml_comments() {
  local category="$1"
  local section="$2"
  local yaml_file="${MOTD_ASSETS_DIR}/comments/${category}.yaml"

  if [[ ! -f "$yaml_file" ]]; then
    return 1
  fi

  if command -v yq >/dev/null 2>&1; then
    (set -o pipefail; yq -r ".${category}.${section}[]" "$yaml_file" 2>/dev/null)
  else
    return 1
  fi
}

# Gets a random comment from one or more collections.
get_comment_collection() {
  local result=()
  local line

  while [[ $# -ge 2 ]]; do
    local category="$1"
    local section="$2"
    shift 2

    local collection_content
    collection_content=$(load_yaml_comments "$category" "$section")
    if [[ $? -eq 0 && -n "$collection_content" ]]; then
      while read -r line; do
          if [[ -n "$line" ]]; then
            result+=("$line")
          fi
      done <<< "$collection_content"
    fi
  done

  if [[ ${#result[@]} -eq 0 ]]; then
    echo "A fancy digital cat comment should be here"
    return 0
  fi

  local selected_comment="${result[$((RANDOM % ${#result[@]}))]}"
  echo "$selected_comment"
}

# Gathers various system information and caches some results.
get_system_info() {
  local cache_dir="$1"

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
    local brew_cache_file="${cache_dir}/brew_outdated"
    if [[ -f "$brew_cache_file" && $(($(date +%s) - $(stat -f %m "$brew_cache_file" 2>/dev/null || stat -c %Y "$brew_cache_file" 2>/dev/null))) -lt 600 ]]; then
      outdated_packages=$(cat "$brew_cache_file")
    else
      outdated_packages=$(brew outdated | wc -l | tr -d ' ')
      echo "${outdated_packages:-0}" >"$brew_cache_file"
    fi
  fi

  hour_num=$((10#$(date +"%H")))

  # Output as key-value pairs for easy parsing later
  cat <<EOF
date_full=${date_full}
time_current=${time_current}
os_info=${os_info}
uptime_info=${uptime_info}
home_disk_space=${home_disk_space}
ram_stats=${ram_stats}
outdated_packages=${outdated_packages}
hour_num=${hour_num}
EOF
}

# Loads and colors the ASCII art file.
load_art() {
  local art_file="$1"

  if [[ ! -f "$art_file" ]]; then
    echo "ASCII art file not found: $art_file"
    return
  fi

  local old_ifs="$IFS"
  IFS=$'\n'
  while IFS= read -r line || [[ -n "$line" ]]; do
    echo "${ART}${line}${RESET}"
  done < "$art_file"
  IFS="$old_ifs"
  echo ""
}

# Builds the greeting part of the MOTD.
build_greeting() {
  local hour_num="$1"
  local date_full="$2"
  local time_current="$3"

  local greeting="Meowvelous day"
  local time_collection_key="morning"

  if (( hour_num >= 5 && hour_num < 12 )); then
    time_collection_key="morning"
  elif (( hour_num >= 12 && hour_num < 18 )); then
    time_collection_key="afternoon"
  elif (( hour_num >= 18 && hour_num < 22 )); then
    time_collection_key="evening"
  else
    time_collection_key="night"
  fi

  local time_comment
  time_comment=$(get_comment_collection "motd" "$time_collection_key")
  if [[ -z "$time_comment" || "$time_comment" == "A fancy digital cat comment should be here" ]]; then
      time_comment="Hope you have a purr-ductive time!"
  fi

  echo "${SECONDARY}${greeting}, сomrade ${DATA}$(whoami)${SECONDARY}!${RESET}"
  echo "${SECONDARY}${time_comment}${RESET}"
  echo ""
  echo "${INFO}Calendar shows ${DATA}${date_full}${NORMAL}.${RESET}"
  echo "${INFO}Clock purrs at ${DATA}${time_current}${NORMAL}.${RESET}"
  echo ""
}

# Builds the system statistics part of the MOTD.
build_system_stats() {
  local system_info="$1"

  local date_full=$(echo "$system_info" | grep '^date_full=' | cut -d'=' -f2-)
  local time_current=$(echo "$system_info" | grep '^time_current=' | cut -d'=' -f2-)
  local os_info=$(echo "$system_info" | grep '^os_info=' | cut -d'=' -f2-)
  local uptime_info=$(echo "$system_info" | grep '^uptime_info=' | cut -d'=' -f2-)
  local home_disk_space=$(echo "$system_info" | grep '^home_disk_space=' | cut -d'=' -f2-)
  local ram_stats=$(echo "$system_info" | grep '^ram_stats=' | cut -d'=' -f2-)
  local outdated_packages=$(echo "$system_info" | grep '^outdated_packages=' | cut -d'=' -f2-)
  local hour_num=$(echo "$system_info" | grep '^hour_num=' | cut -d'=' -f2-)

  # Set defaults if values are empty
  date_full="${date_full:-$(date +"%A, %B %d, %Y")}"
  time_current="${time_current:-$(date +"%H:%M:%S")}"
  os_info="${os_info:-$(uname -srm)}"
  outdated_packages="${outdated_packages:-0}"
  hour_num="${hour_num:-$((10#$(date +"%H")))}"

  build_greeting "$hour_num" "$date_full" "$time_current"

  echo "${HEADER}Let me tell you about your digital territory, comrade:${RESET}"
  echo "  ${BULLET}❯${RESET} ${SECONDARY}System:${RESET}     ${DATA}${os_info}${RESET}"
  echo "  ${BULLET}❯${RESET} ${SECONDARY}Shell:${RESET}      ${DATA}${SHELL}${RESET}"

  # --- Uptime ---
  local uptime_collections=("uptime" "base")
  [[ -z "$uptime_info" ]] && uptime_collections+=("uptime" "fallback")
  local random_uptime_comment
  random_uptime_comment=$(get_comment_collection "${uptime_collections[@]}")
  if [[ "$random_uptime_comment" == "A fancy digital cat comment should be here" ]]; then
    random_uptime_comment="Your system is up and running!"
  fi
  echo "  ${BULLET}❯${RESET} ${SECONDARY}Uptime:${RESET}     ${DATA}${uptime_info:-"Unknown"}${RESET}"
  echo "                ${SUCCESS}(${random_uptime_comment})${RESET}"

  # --- Disk ---
  local disk_collections=("disk" "base")
  [[ -z "$home_disk_space" ]] && disk_collections+=("disk" "fallback")
  local random_disk_comment
  random_disk_comment=$(get_comment_collection "${disk_collections[@]}")
  if [[ "$random_disk_comment" == "A fancy digital cat comment should be here" ]]; then
    random_disk_comment="May your storage be plentiful!"
  fi
  echo "  ${BULLET}❯${RESET} ${SECONDARY}Disk:${RESET}       ${DATA}${home_disk_space:-"Unable to determine"}${RESET}"
  echo "                ${SUCCESS}(${random_disk_comment})${RESET}"

  # --- RAM ---
  local ram_collections=("ram" "base")
  [[ -z "$ram_stats" ]] && ram_collections+=("ram" "fallback")
  local random_ram_comment
  random_ram_comment=$(get_comment_collection "${ram_collections[@]}")
  if [[ "$random_ram_comment" == "A fancy digital cat comment should be here" ]]; then
    random_ram_comment="May your memory serve you well, comrade!"
  fi
  echo "  ${BULLET}❯${RESET} ${SECONDARY}RAM:${RESET}        ${DATA}${ram_stats:-"Unknown"}${RESET}"
  echo "                ${SUCCESS}(${random_ram_comment})${RESET}"

  # --- Packages ---
  if [[ "$outdated_packages" -gt 0 ]]; then
    local random_package_comment="Time for some updates!"
    echo "  ${BULLET}❯${RESET} ${SECONDARY}Updates:${RESET}    ${WARNING}${outdated_packages} packages need updating${RESET}"
    echo "                ${SUCCESS}(${random_package_comment})${RESET}"
  fi

  echo ""
}

# Display ASCII art and system stats side by side.
display_art_and_stats() {
  local art_content="$1"
  local stats_content="$2"

  local -a art_array
  local -a stats_array
  local old_ifs="$IFS"
  IFS=$'\n'
  while IFS= read -r line || [[ -n "$line" ]]; do art_array+=("$line"); done <<< "$art_content"
  while IFS= read -r line || [[ -n "$line" ]]; do stats_array+=("$line"); done <<< "$stats_content"
  IFS="$old_ifs"

  local max_art_width=0
  local num_art_lines=${#art_array[@]}
  local num_stats_lines=${#stats_array[@]}
  local max_total_lines=$((num_art_lines > num_stats_lines ? num_art_lines : num_stats_lines))
  local column_gap="  "
  local ansi_regex=$'\x1b\\[[0-9;]*m'

  # Calculate max width of art (without ANSI codes)
  for art_line in "${art_array[@]}"; do
    local plain_art_line="${art_line//$ansi_regex/}"
    if ((${#plain_art_line} > max_art_width)); then
      max_art_width=${#plain_art_line}
    fi
  done

  # Display side by side
  for ((i=0; i < max_total_lines; i++)); do
    local art_line="${art_array[i]:-}"
    local stats_line="${stats_array[i]:-}"

    local plain_art_line="${art_line//$ansi_regex/}"
    local current_plain_art_len=${#plain_art_line}

    printf "%b" "$art_line"

    local padding_spaces=$((max_art_width - current_plain_art_len))
    if ((padding_spaces > 0)); then
      printf "%*s" "$padding_spaces" ""
    fi

    printf "%s%b\\n" "$column_gap" "$stats_line"
  done
}

# Main function to orchestrate the MOTD display.
show_motd() {
  if ! command -v yq >/dev/null 2>&1; then
    echo "Warning: 'yq' is not installed. Cannot display random comments." >&2
  fi

  local system_info art_content stats_content
  system_info=$(get_system_info "$MOTD_CACHE_DIR")
  art_content=$(load_art "$MOTD_ASCII_ART_FILE")
  stats_content=$(build_system_stats "$system_info")

  display_art_and_stats "$art_content" "$stats_content"
}

# If the script is executed directly (not sourced), run the main function.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  show_motd
fi