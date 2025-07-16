#!/usr/bin/env bash

# lib/greeting/build.sh - Build greeting message for terminal

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_BUILD_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_BUILD_SOURCED=1

build_greeting() {
  local greeting="Meowvelous day"
  local time_collection_key="greeting_morning"

  if (( HOUR_NUM >= 5 && HOUR_NUM < 12 )); then
    time_collection_key="greeting_morning"
  elif (( HOUR_NUM >= 12 && HOUR_NUM < 18 )); then
    time_collection_key="greeting_afternoon"
  elif (( HOUR_NUM >= 18 && HOUR_NUM < 22 )); then
    time_collection_key="greeting_evening"
  else
    time_collection_key="greeting_night"
  fi

  local time_comment
  time_comment=$(get_random_comment "$time_collection_key")
  if [[ -z "$time_comment" || "$time_comment" == "No comments available for "* || "$time_comment" == "No usable comments in "* ]]; then
      time_comment="Hope you have a purr-ductive time!"
  fi

  commentary_lines+=("${SECONDARY}${greeting}, сomrade ${DATA}$(whoami)${SECONDARY}!${RESET}")
  commentary_lines+=("${SECONDARY}${time_comment}${RESET}")
  commentary_lines+=("")
  commentary_lines+=("${INFO}Calendar shows ${DATA}${DATE_FULL}${NORMAL}.${RESET}")
  commentary_lines+=("${INFO}Clock purrs at ${DATA}${TIME_CURRENT}${NORMAL}.${RESET}")
  commentary_lines+=("")
}

# Functional version that takes system info as parameters
build_greeting_functional() {
  local hour_num="$1"
  local date_full="$2"
  local time_current="$3"
  local -n result_lines=$4  # nameref to output array
  
  local greeting="Meowvelous day"
  local time_collection_key="greeting_morning"

  if (( hour_num >= 5 && hour_num < 12 )); then
    time_collection_key="greeting_morning"
  elif (( hour_num >= 12 && hour_num < 18 )); then
    time_collection_key="greeting_afternoon"
  elif (( hour_num >= 18 && hour_num < 22 )); then
    time_collection_key="greeting_evening"
  else
    time_collection_key="greeting_night"
  fi

  local time_comment
  time_comment=$(get_random_comment "$time_collection_key")
  if [[ -z "$time_comment" || "$time_comment" == "No comments available for "* || "$time_comment" == "No usable comments in "* ]]; then
      time_comment="Hope you have a purr-ductive time!"
  fi

  result_lines+=("${SECONDARY}${greeting}, сomrade ${DATA}$(whoami)${SECONDARY}!${RESET}")
  result_lines+=("${SECONDARY}${time_comment}${RESET}")
  result_lines+=("")
  result_lines+=("${INFO}Calendar shows ${DATA}${date_full}${NORMAL}.${RESET}")
  result_lines+=("${INFO}Clock purrs at ${DATA}${time_current}${NORMAL}.${RESET}")
  result_lines+=("")
}

build_system_stats() {
  init_comment_collections
  build_greeting

  commentary_lines+=("${HEADER}Let me tell you about your digital territory, comrade:${RESET}")
  commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}System:${RESET}     ${DATA}${OS_INFO}${RESET}")
  commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}Shell:${RESET}      ${DATA}${SHELL}${RESET}")

  local uptime_collections=("uptime_base")
  if [[ -z "$UPTIME_INFO" ]]; then
    uptime_collections+=("uptime_fallback")
  fi

  local random_uptime_comment
  random_uptime_comment=$(get_comment_collection "${uptime_collections[@]}")
  if [[ -z "$random_uptime_comment" || "$random_uptime_comment" == "A fancy digital cat comment should be here" ]]; then
    random_uptime_comment="Your system is up and running!"
  fi
  commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}Uptime:${RESET}     ${DATA}${UPTIME_INFO:-"Unknown"}${RESET}")
  commentary_lines+=("                ${SUCCESS}(${random_uptime_comment})${RESET}")

  local disk_collections=("disk_base")
  if [[ -z "$HOME_DISK_SPACE" ]]; then
    disk_collections+=("disk_fallback")
  fi

  local random_disk_comment
  random_disk_comment=$(get_comment_collection "${disk_collections[@]}")
  if [[ -z "$random_disk_comment" || "$random_disk_comment" == "A fancy digital cat comment should be here" ]]; then
    random_disk_comment="May your storage be plentiful!"
  fi
  commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}Disk:${RESET}       ${DATA}${HOME_DISK_SPACE:-"Unable to determine"}${RESET}")
  commentary_lines+=("                ${SUCCESS}(${random_disk_comment})${RESET}")

  local ram_collections=("ram_base")
  if [[ "$RAM_STATS" == "N/A" || -z "$RAM_STATS" ]]; then
    ram_collections+=("ram_fallback")
  fi

  local random_ram_comment
  random_ram_comment=$(get_comment_collection "${ram_collections[@]}")
  if [[ -z "$random_ram_comment" || "$random_ram_comment" == "A fancy digital cat comment should be here" ]]; then
    random_ram_comment="May your memory serve you well, comrade!"
  fi
  commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}RAM:${RESET}        ${DATA}${RAM_STATS:-"Unknown"}${RESET}")
  commentary_lines+=("                ${SUCCESS}(${random_ram_comment})${RESET}")

  local random_package_comment="Time for some updates!"
  if [[ "$OUTDATED_PACKAGES" != "N/A" && "$OUTDATED_PACKAGES" -gt 0 ]]; then
    commentary_lines+=("  ${BULLET}❯${RESET} ${SECONDARY}Updates:${RESET}    ${WARNING}${OUTDATED_PACKAGES} packages need updating${RESET}")
    commentary_lines+=("                ${SUCCESS}(${random_package_comment})${RESET}")
  fi

  commentary_lines+=("")
}
