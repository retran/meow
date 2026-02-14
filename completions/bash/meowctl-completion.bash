# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: completions/bash/meowctl-completion.bash
# @brief: Bash completion for meowctl
# @author: Andrew Vasilyev
# @license: MIT

_meowctl_list_presets() {
  local meow="${MEOW:-$HOME/.meow}"
  if [[ -d "$meow/presets" ]]; then
    find "$meow/presets" -maxdepth 1 -type d -not -name "presets" -exec basename {} \; 2>/dev/null
  fi
}

_meowctl_list_components() {
  local meow="${MEOW:-$HOME/.meow}"
  if [[ -d "$meow/components" ]]; then
    find "$meow/components" -maxdepth 1 -type d -not -name "components" -exec basename {} \; 2>/dev/null
  fi
}

_meowctl_list_installed_components() {
  local meow="${MEOW:-$HOME/.meow}"
  if [[ -d "$meow/.installed/components" ]]; then
    find "$meow/.installed/components" -type l -exec basename {} \; 2>/dev/null
  fi
}

_meowctl_list_theme_presets() {
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

_meowctl_list_theme_variants() {
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

_meowctl() {
  local cur prev words cword
  _init_completion || return

  local commands="install update uninstall list component config theme backup help"
  local component_commands="list status install uninstall update"
  local theme_commands="apply toggle preset auto manual status preview list build"
  local config_commands="get set list"
  local backup_commands="list restore"

  # First level command completion
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return 0
  fi

  # Second level completion
  case "${words[1]}" in
    install)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$(_meowctl_list_presets)" -- "$cur"))
      elif [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "--force --verbose --dry-run --help" -- "$cur"))
      fi
      ;;
    uninstall)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$(_meowctl_list_presets) all" -- "$cur"))
      elif [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "--verbose --dry-run --help" -- "$cur"))
      fi
      ;;
    update)
      if [[ $cword -ge 2 && ! $cur =~ ^- ]]; then
        COMPREPLY=($(compgen -W "$(_meowctl_list_presets)" -- "$cur"))
      elif [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "--pull --verbose --dry-run --help" -- "$cur"))
      fi
      ;;
    component)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$component_commands" -- "$cur"))
      elif [[ $cword -ge 3 ]]; then
        case "${words[2]}" in
          install|update)
            COMPREPLY=($(compgen -W "$(_meowctl_list_components)" -- "$cur"))
            ;;
          uninstall)
            COMPREPLY=($(compgen -W "$(_meowctl_list_installed_components)" -- "$cur"))
            ;;
        esac
      fi
      ;;
    theme)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$theme_commands" -- "$cur"))
      elif [[ $cword -ge 3 ]]; then
        case "${words[2]}" in
          preset|preview)
            if [[ $cword -eq 3 ]]; then
              COMPREPLY=($(compgen -W "$(_meowctl_list_theme_presets)" -- "$cur"))
            elif [[ $cword -eq 4 ]]; then
              COMPREPLY=($(compgen -W "$(_meowctl_list_theme_variants "${words[3]}")" -- "$cur"))
            elif [[ $cword -eq 5 && "${words[2]}" == "preset" ]]; then
              COMPREPLY=($(compgen -W "light dark" -- "$cur"))
            fi
            ;;
          build)
            if [[ $cur == -* ]]; then
              COMPREPLY=($(compgen -W "--preset --variant --parallel" -- "$cur"))
            elif [[ "${words[cword-1]}" == "--preset" ]]; then
              COMPREPLY=($(compgen -W "$(_meowctl_list_theme_presets)" -- "$cur"))
            fi
            ;;
        esac
      fi
      ;;
    config)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$config_commands" -- "$cur"))
      elif [[ $cword -eq 3 && ("${words[2]}" == "get" || "${words[2]}" == "set") ]]; then
        COMPREPLY=($(compgen -W "theme.mode theme.current theme.light.preset theme.light.variant theme.dark.preset theme.dark.variant" -- "$cur"))
      fi
      ;;
    backup)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$backup_commands" -- "$cur"))
      fi
      ;;
    help)
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
      fi
      ;;
  esac

  # Global options
  if [[ $cur == -* ]]; then
    local global_opts="--verbose --dry-run --help"
    COMPREPLY+=($(compgen -W "$global_opts" -- "$cur"))
  fi

  return 0
}

complete -F _meowctl meowctl
