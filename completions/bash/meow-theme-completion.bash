# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: completions/bash/meow-theme-completion.bash
# @brief: Bash completion for meow-theme
# @author: Andrew Vasilyev
# @license: MIT

_meow_theme_list_presets() {
  local meow="${MEOW:-$HOME/.meow}"
  local theme_db="$meow/themes.yaml"
  
  if [[ -f "$theme_db" ]]; then
    if command -v yq >/dev/null 2>&1; then
      yq eval '.themes | keys | .[]' "$theme_db" 2>/dev/null
    else
      awk '/^themes:/,/^[a-zA-Z]/ { if (/^  [a-zA-Z]/) { gsub(/:/, ""); gsub(/^  /, ""); print } }' "$theme_db" | sort -u
    fi
  fi
}

_meow_theme_list_variants() {
  local preset="$1"
  local meow="${MEOW:-$HOME/.meow}"
  local theme_db="$meow/themes.yaml"
  
  if [[ -f "$theme_db" ]]; then
    if command -v yq >/dev/null 2>&1; then
      yq eval ".themes.${preset}.variants | keys | .[]" "$theme_db" 2>/dev/null
    else
      awk "/^  ${preset}:/,/^  [a-zA-Z]/ { if (/^    [a-zA-Z]/ && !/variants:/) { gsub(/:/, \"\"); gsub(/^    /, \"\"); print } }" "$theme_db" | sort -u
    fi
  fi
}

_meow_theme() {
  local cur prev words cword
  _init_completion || return

  local commands="apply toggle preset auto manual status preview list"

  # First level command completion
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return 0
  fi

  # Second level completion
  case "${words[1]}" in
    preset|preview)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$(_meow_theme_list_presets)" -- "$cur"))
      elif [[ $cword -eq 3 ]]; then
        COMPREPLY=($(compgen -W "$(_meow_theme_list_variants "${words[2]}")" -- "$cur"))
      elif [[ $cword -eq 4 && "${words[1]}" == "preset" ]]; then
        COMPREPLY=($(compgen -W "light dark" -- "$cur"))
      fi
      ;;
  esac

  return 0
}

complete -F _meow_theme meow-theme
