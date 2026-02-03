#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/config/config.sh
# @brief: YAML-backed configuration system for .meow environment
# @author: Andrew Vasilyev
# @license: MIT

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  set -euo pipefail
fi

MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
MEOW_CONFIG_FILE="$MEOW_CONFIG_DIR/config.yaml"

source "${MEOW}/lib/core/tools.sh"
source "${MEOW}/lib/core/yaml.sh"

setup_meow_config_dir() {
  mkdir -p "$MEOW_CONFIG_DIR"
}

_meow_config_default() {
  cat <<'EOF'
theme:
  mode: auto
  current: dark
  light:
    preset: catppuccin
    variant: latte
  dark:
    preset: catppuccin
    variant: mocha
EOF
}

_meow_config_init() {
  setup_meow_config_dir
  if [[ -f "$MEOW_CONFIG_FILE" ]]; then
    return 0
  fi

  _meow_config_default >"$MEOW_CONFIG_FILE"
  echo "Created default config at $MEOW_CONFIG_FILE" >&2
}

_ensure_yq() {
  if ! command -v yq >/dev/null 2>&1 && [ ! -x "/usr/local/bin/yq" ]; then
    ensure_yq
  fi
}

_meow_config_path_to_yaml() {
  local key="$1"
  if [[ "$key" == .* ]]; then
    echo "$key"
    return 0
  fi
  echo ".${key}"
}

meow_config_get() {
  local key="$1"
  local default="${2:-}"
  _meow_config_init

  local yaml_path
  yaml_path=$(_meow_config_path_to_yaml "$key")

  local value
  value=$(read_yaml_value "$MEOW_CONFIG_FILE" "$yaml_path")
  if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
    echo "$default"
    return 1
  fi

  value=${value%\"}
  value=${value#\"}
  echo "$value"
}

meow_config_set() {
  local key="$1"
  local value="$2"
  _meow_config_init
  _ensure_yq

  local yaml_path
  yaml_path=$(_meow_config_path_to_yaml "$key")

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  if [[ "$value" == "true" || "$value" == "false" || "$value" =~ ^[0-9]+$ ]]; then
    "$yq_cmd" eval -i "$yaml_path = $value" "$MEOW_CONFIG_FILE"
  else
    "$yq_cmd" eval -i "$yaml_path = \"$value\"" "$MEOW_CONFIG_FILE"
  fi
}

meow_config_delete() {
  local key="$1"
  _meow_config_init
  _ensure_yq

  local yaml_path
  yaml_path=$(_meow_config_path_to_yaml "$key")

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  "$yq_cmd" eval -i "del($yaml_path)" "$MEOW_CONFIG_FILE"
}

meow_config_unset() {
  meow_config_delete "$@"
}

meow_config_list() {
  local namespace="${1:-}"
  _meow_config_init
  _ensure_yq

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  if [[ -z "$namespace" ]]; then
    "$yq_cmd" eval '.' "$MEOW_CONFIG_FILE"
  else
    "$yq_cmd" eval ".${namespace}" "$MEOW_CONFIG_FILE"
  fi
}

meow_config_namespace() {
  local namespace="$1"
  _meow_config_init
  _ensure_yq

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  local output=""
  local key
  while IFS= read -r key; do
    local value
    value=$($yq_cmd eval -r ".$namespace.$key" "$MEOW_CONFIG_FILE" 2>/dev/null || true)
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
      continue
    fi
    local var_name
    var_name=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '.' '_')
    output+="${var_name}='${value}'\n"
  done < <($yq_cmd eval -r ".$namespace | keys | .[]" "$MEOW_CONFIG_FILE" 2>/dev/null || true)

  echo -e "$output"
}

meow_config_edit() {
  _meow_config_init
  if command -v gum >/dev/null 2>&1; then
    local namespaces=("theme")
    local namespace
    namespace=$(printf '%s\n' "${namespaces[@]}" | gum filter --placeholder "Select namespace...")

    if [[ -n "$namespace" ]]; then
      echo "Config values for $namespace:"
      meow_config_list "$namespace"
      echo ""

      local action
      action=$(gum choose "Add/Update value" "Delete value" "Cancel")

      case "$action" in
        "Add/Update value")
          local key
          key=$(gum input --placeholder "Key (without namespace prefix)")
          if [[ -n "$key" ]]; then
            local value
            value=$(gum input --placeholder "Value" --value "$(meow_config_get "${namespace}.${key}")")
            if [[ -n "$value" ]]; then
              meow_config_set "${namespace}.${key}" "$value"
              echo "Set ${namespace}.${key} = $value"
            fi
          fi
          ;;
        "Delete value")
          local key
          key=$(gum input --placeholder "Key (without namespace prefix)")
          if [[ -n "$key" ]]; then
            meow_config_delete "${namespace}.${key}"
            echo "Deleted ${namespace}.${key}"
          fi
          ;;
      esac
    fi
  else
    "${EDITOR:-vim}" "$MEOW_CONFIG_FILE"
  fi
}

meow_config_show() {
  _meow_config_init

  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border double --border-foreground 212 \
      --margin "1 2" --padding "1 2" \
      "Meow Configuration" \
      "" \
      "Location: $MEOW_CONFIG_FILE"
    echo ""
  else
    echo "=== Meow Configuration ==="
    echo "Location: $MEOW_CONFIG_FILE"
    echo ""
  fi

  echo "[theme]"
  meow_config_list "theme" || echo "  (no values)"
  echo ""
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  case "${1:-}" in
    get)
      shift
      meow_config_get "$@"
      ;;
    set)
      shift
      meow_config_set "$@"
      ;;
    delete)
      shift
      meow_config_delete "$@"
      ;;
    list)
      shift
      meow_config_list "$@"
      ;;
    namespace)
      shift
      meow_config_namespace "$@"
      ;;
    edit)
      meow_config_edit
      ;;
    show)
      meow_config_show
      ;;
    *)
      cat <<EOF
Usage: config.sh <command> [args]

Commands:
  get KEY [DEFAULT]       Get config value
  set KEY VALUE           Set config value
  delete KEY              Delete config value
  list [NAMESPACE]        List config values
  namespace NAMESPACE     Export namespace as shell variables
  edit                    Interactive config editor
  show                    Show all configuration

Examples:
  config.sh get theme.mode auto
  config.sh set theme.current dark
  config.sh list theme
  eval "\$(config.sh namespace theme)"
EOF
      exit 1
      ;;
  esac
fi
