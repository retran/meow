#!/usr/bin/env bash

# lib/greeting/display.sh - Functions for displaying greeting and system stats

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_DISPLAY_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_DISPLAY_SOURCED=1

display_art_and_stats() {
  local max_art_width=0
  local num_art_lines=${#art[@]}
  local num_commentary_lines=${#commentary_lines[@]}
  local max_total_lines=$((num_art_lines > num_commentary_lines ? num_art_lines : num_commentary_lines))
  local column_gap="  "
  local art_line_colored=""
  local commentary_line_colored=""
  local plain_art_line_for_len=""

  for ((i=0; i<num_art_lines; i++)); do
    plain_art_line_for_len=$(echo "${art[i]}" | sed 's/\x1b\[[0-9;]*m//g')
    if ((${#plain_art_line_for_len} > max_art_width)); then
      max_art_width=${#plain_art_line_for_len}
    fi
  done

  for ((i=0; i < max_total_lines; i++)); do
    art_line_colored=""
    local current_plain_art_len=0
    if ((i < num_art_lines)); then
      art_line_colored="${art[i]}"
      plain_art_line_for_len=$(echo "${art_line_colored}" | sed 's/\x1b\[[0-9;]*m//g')
      current_plain_art_len=${#plain_art_line_for_len}
    fi

    commentary_line_colored=""
    if ((i < num_commentary_lines)); then
      commentary_line_colored="${commentary_lines[i]}"
    fi

    printf "%b" "${art_line_colored}"

    local padding_spaces=$((max_art_width - current_plain_art_len))
    if ((padding_spaces < 0)); then
      padding_spaces=0
    fi

    if ((padding_spaces > 0)); then
      printf "%*s" "$padding_spaces" ""
    fi

    printf "%s" "$column_gap"
    printf "%b" "${commentary_line_colored}"
    printf "\\n"
  done
}

format_content_output() {
  local header="$1"
  local content="$2"
  local total_width=100
  local content_wrap_width=$((total_width - 2))

  echo "${HEADER}${header}${RESET}"

  if [[ -n "$content" ]]; then
    if command -v fold &>/dev/null; then
      echo "$content" | fold -s -w "$content_wrap_width" | while IFS= read -r line; do
        echo "  ${CONTENT}${line}${RESET}"
      done
    else
      echo "  ${CONTENT}${content}${RESET}"
    fi
  fi
}
