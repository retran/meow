#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/zellij/zjstatus-colors.sh
# @brief: Shared helper to resolve and emit the zjstatus color block for a
#         given preset/variant.  Sourced by apply-theme-zellij.
# @author: Andrew Vasilyev
# @license: MIT
#
# Requires theme_get_palette_color to already be available (source theme.sh
# before sourcing this file).
#
# Usage:
#   source "$MEOW_ROOT/lib/zellij/zjstatus-colors.sh"
#   zjstatus_build_color_block "$PRESET" "$VARIANT"
#   # Prints the replacement block to stdout.
#
# Returns 1 if bg/fg cannot be resolved.

zjstatus_build_color_block() {
  local preset="$1"
  local variant="$2"

  # Return first non-empty palette value from an ordered list of key candidates.
  _zjc_get() {
    local result=""
    for key in "$@"; do
      result=$(theme_get_palette_color "$preset" "$variant" "$key" 2>/dev/null || true)
      if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
        return
      fi
    done
    echo ""
  }

  # ── Semantic color roles ────────────────────────────────────────────────────
  # bar background / foreground
  local _bg _fg
  _bg=$(_zjc_get "bg"       "base"     "bg1")
  _fg=$(_zjc_get "fg"       "text"     "fg1")

  if [[ -z "$_bg" || -z "$_fg" ]]; then
    echo "zjstatus_build_color_block: cannot resolve bg/fg for $preset/$variant" >&2
    return 1
  fi

  # selection: active tab background
  local _sel
  _sel=$(_zjc_get "surface0" "bg_highlight" "bg_visual" "sel0" "bg1" "bg2" "mantle")
  [[ -z "$_sel" ]] && _sel="$_bg"

  # dimmed: normal tab fg, normal mode indicator
  local _dim
  _dim=$(_zjc_get "overlay1" "comment" "gray" "subtext0" "fg_gutter" "dark5")
  [[ -z "$_dim" ]] && _dim="$_fg"

  # subtle: datetime text (slightly lighter than dim)
  local _subtle
  _subtle=$(_zjc_get "subtext1" "overlay2" "comment" "gray" "fg_gutter")
  [[ -z "$_subtle" ]] && _subtle="$_fg"

  # identity/accent: session pill — teal/cyan family
  local _teal
  _teal=$(_zjc_get "teal" "cyan" "sapphire" "water" "foam" "pine" "sky")
  [[ -z "$_teal" ]] && _teal="$_fg"

  # pane mode — blue family
  local _blue
  _blue=$(_zjc_get "blue" "water" "sapphire" "sky" "blue0" "pine" "foam")
  [[ -z "$_blue" ]] && _blue="$_fg"

  # tab mode — purple/mauve family
  local _mauve
  _mauve=$(_zjc_get "mauve" "purple" "magenta" "blossom" "iris" "violet" "pink")
  [[ -z "$_mauve" ]] && _mauve="$_fg"

  # scroll / cpu widget — green family
  local _green
  _green=$(_zjc_get "green" "leaf" "teal" "pine" "green1")
  [[ -z "$_green" ]] && _green="$_fg"

  # search / resize / rename — yellow/amber family
  local _yellow
  _yellow=$(_zjc_get "yellow" "gold" "wood" "peach" "orange" "highlight")
  [[ -z "$_yellow" ]] && _yellow="$_fg"

  # move mode / battery — orange family
  local _orange
  _orange=$(_zjc_get "orange" "peach" "wood" "yellow" "gold" "highlight")
  [[ -z "$_orange" ]] && _orange="$_fg"

  # locked mode — red family
  local _red
  _red=$(_zjc_get "red" "love" "rose" "danger" "error" "maroon")
  [[ -z "$_red" ]] && _red="$_fg"

  # ── Emit the KDL color block ────────────────────────────────────────────────
  printf '%s\n' \
    "                // ZJSTATUS_COLORS_BEGIN (managed by apply-theme-zellij — do not edit manually)" \
    "                 // bg=${_bg} fg=${_fg} sel=${_sel} dim=${_dim} subtle=${_subtle}" \
    "                 // teal=${_teal} blue=${_blue} mauve=${_mauve} green=${_green}" \
    "                 // yellow=${_yellow} orange=${_orange} red=${_red}" \
    "                 format_left              \"{mode}#[fg=${_bg},bg=${_teal},bold] {session} #[fg=${_teal},bg=${_bg}]{tabs}\"" \
    "                 format_space             \"#[bg=${_bg}]\"" \
    "                 tab_normal               \"#[fg=${_dim},bg=${_bg}] {index} {name} \"" \
    "                 tab_active               \"#[fg=${_fg},bg=${_sel},bold] {index} {name} \"" \
    "                 tab_separator            \"#[fg=${_sel},bg=${_bg}]\"" \
    "                 mode_normal              \"#[fg=${_dim},bg=${_bg}] NORMAL \"" \
    "                 mode_pane                \"#[fg=${_bg},bg=${_blue},bold] PANE \"" \
    "                 mode_tab                 \"#[fg=${_bg},bg=${_mauve},bold] TAB \"" \
    "                 mode_scroll              \"#[fg=${_bg},bg=${_green},bold] SCROLL \"" \
    "                 mode_search              \"#[fg=${_bg},bg=${_yellow},bold] SEARCH \"" \
    "                 mode_enter_search        \"#[fg=${_bg},bg=${_yellow},bold] SEARCH \"" \
    "                 mode_session             \"#[fg=${_bg},bg=${_teal},bold] SESSION \"" \
    "                 mode_move                \"#[fg=${_bg},bg=${_orange},bold] MOVE \"" \
    "                 mode_locked              \"#[fg=${_bg},bg=${_red},bold] LOCKED \"" \
    "                 mode_resize              \"#[fg=${_bg},bg=${_yellow},bold] RESIZE \"" \
    "                 mode_rename_pane         \"#[fg=${_bg},bg=${_yellow},bold] RENAME \"" \
    "                 mode_rename_tab          \"#[fg=${_bg},bg=${_yellow},bold] RENAME \"" \
    "                 pipe_vpn_format          \"{output}  \"" \
    "                 pipe_focus_format        \"{output}  \"" \
    "                 pipe_keyboard_format     \"{output}  \"" \
    "                 pipe_cpu_format          \"{output}  \"" \
    "                 pipe_memory_format       \"{output}  \"" \
    "                 pipe_battery_format      \"{output}  \"" \
    "                 pipe_date_format         \"{output}  \"" \
    "                 pipe_time_format         \"{output}\"" \
    "                 datetime                 \"#[fg=${_subtle},bg=${_bg}] {format}\"" \
    "                 // ZJSTATUS_COLORS_END"
}

# Write a Lua color config file that init.lua reads to get theme-aware colors.
# Called by apply-theme-zellij after zjstatus_build_color_block succeeds.
zjstatus_write_lua_colors() {
  local preset="$1"
  local variant="$2"
  local out_file="${3:-$HOME/.local/share/zjstatus-widgets/colors.lua}"

  _zjc_get() {
    local result=""
    for key in "$@"; do
      result=$(theme_get_palette_color "$preset" "$variant" "$key" 2>/dev/null || true)
      if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
        return
      fi
    done
    echo ""
  }

  local _bg _green _yellow _orange _red _mauve _blue
  _bg=$(_zjc_get     "bg"     "base"     "bg1")
  _green=$(_zjc_get  "green"  "leaf"     "teal"   "pine"   "green1")
  _yellow=$(_zjc_get "yellow" "gold"     "wood"   "peach"  "orange" "highlight")
  _orange=$(_zjc_get "orange" "peach"    "wood"   "yellow" "gold"   "highlight")
  _red=$(_zjc_get    "red"    "love"     "rose"   "danger" "error"  "maroon")
  _mauve=$(_zjc_get  "mauve"  "purple"   "magenta" "blossom" "iris" "violet" "pink")
  _blue=$(_zjc_get   "blue"   "water"    "sapphire" "sky"  "blue0"  "pine"   "foam")

  [[ -z "$_bg"     ]] && { echo "zjstatus_write_lua_colors: cannot resolve bg for $preset/$variant" >&2; return 1; }
  [[ -z "$_green"  ]] && _green="$_blue"
  [[ -z "$_yellow" ]] && _yellow="$_blue"
  [[ -z "$_orange" ]] && _orange="$_blue"
  [[ -z "$_red"    ]] && _red="$_blue"
  [[ -z "$_mauve"  ]] && _mauve="$_blue"
  [[ -z "$_blue"   ]] && { echo "zjstatus_write_lua_colors: cannot resolve blue for $preset/$variant" >&2; return 1; }

  mkdir -p "$(dirname "$out_file")"
  cat > "$out_file" <<LUA
-- Auto-generated by apply-theme-zellij — do not edit manually.
-- Theme: ${preset} / ${variant}
return {
  bg     = "${_bg}",
  green  = "${_green}",
  yellow = "${_yellow}",
  orange = "${_orange}",
  red    = "${_red}",
  mauve  = "${_mauve}",
  blue   = "${_blue}",
}
LUA
  echo "Wrote zjstatus Lua colors to $out_file"
}
