#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if ! command -v lua >/dev/null 2>&1; then
  ui_warning "$(fmt "lua_dev_lua_not_found_skip")"
  exit 0
fi

ui_action_start "$(fmt "lua_dev_configuring")"

if command -v luarocks >/dev/null 2>&1; then
  ui_info "$(fmt "lua_dev_configuring_luarocks")"

  luarocks_config_dir="$HOME/.luarocks"
  mkdir -p "$luarocks_config_dir" 2>/dev/null || true

  if [[ ! -f "$luarocks_config_dir/config-5.4.lua" ]]; then
    cat > "$luarocks_config_dir/config-5.4.lua" << 'EOF'
rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/opt/homebrew" };
}
variables = {
   LUA_DIR = "/opt/homebrew",
   LUA_BINDIR = "/opt/homebrew/bin",
}
EOF
  fi

  ui_info "$(fmt "lua_dev_installing_essential_rocks")"
  luarocks install --local inspect 2>/dev/null || true
  luarocks install --local penlight 2>/dev/null || true
  luarocks install --local busted 2>/dev/null || true
fi

if command -v lua-language-server >/dev/null 2>&1; then
  ui_info "$(fmt "lua_dev_configuring_language_server")"

  lua_ls_config_dir="$HOME/.config/lua-language-server"
  mkdir -p "$lua_ls_config_dir" 2>/dev/null || true

  if [[ ! -f "$lua_ls_config_dir/config.json" ]]; then
    cat > "$lua_ls_config_dir/config.json" << 'EOF'
{
  "Lua.runtime.version": "Lua 5.4",
  "Lua.diagnostics.globals": ["vim"],
  "Lua.workspace.library": {
    "/opt/homebrew/share/lua/5.4": true,
    "/opt/homebrew/lib/lua/5.4": true
  },
  "Lua.telemetry.enable": false
}
EOF
  fi
fi

ui_action_success "$(fmt "lua_dev_configured_successfully")"
