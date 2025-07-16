#!/usr/bin/env bash

# lib/greeting/art.sh - ASCII art greeting for terminal

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_ART_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_ART_SOURCED=1

load_art() {
  if [[ ! -f "$ASCII_ART_FILE" ]]; then
    art+=("ASCII art file not found: $ASCII_ART_FILE")
    return
  fi

  local old_ifs="$IFS"
  IFS=$'\n'
  while IFS= read -r line || [[ -n "$line" ]]; do
    art+=("${ART}${line}${RESET}")
  done < "$ASCII_ART_FILE"
  IFS="$old_ifs"
  art+=('')
}

# Functional version that takes art file path and returns art array
load_art_functional() {
  local art_file="$1"
  local -n result_art=$2  # nameref to output array
  
  if [[ ! -f "$art_file" ]]; then
    result_art+=("ASCII art file not found: $art_file")
    return
  fi

  local old_ifs="$IFS"
  IFS=$'\n'
  while IFS= read -r line || [[ -n "$line" ]]; do
    result_art+=("${ART}${line}${RESET}")
  done < "$art_file"
  IFS="$old_ifs"
  result_art+=('')
}
