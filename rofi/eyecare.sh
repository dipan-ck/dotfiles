#!/usr/bin/env bash
## Applet : Eye Care (hyprsunset blue light control)

ROFI_DIR="$HOME/.config/rofi"
THEME="$ROFI_DIR/eyecare.rasi"
STATE_FILE="/tmp/hyprsunset_state"

# Read current state
current=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

# Build status label for mesg
case "$current" in
warm) status="󱩌  Active — Warm (4500K)" ;;
warmer) status="󰛨  Active — Warmer (3500K)" ;;
hot) status="󰈉  Active — Hot (2700K)" ;;
*) status="󰈈  Off — No filter applied" ;;
esac

prompt='Eye Care'
mesg="Current: $status"

# Options
option_1="<span font='18'>󰈈</span>  Off  —  No filter"
option_2="<span font='18'>󱩌</span>  Warm  —  4500K"
option_3="<span font='18'>󰛨</span>  Warmer  —  3500K"
option_4="<span font='18'>󰈉</span>  Hot  —  2700K"

rofi_cmd() {
  rofi \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "$THEME"
}

run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

# Apply temperature
apply() {
  pkill hyprsunset 2>/dev/null
  sleep 0.1
  case "$1" in
  off)
    echo "off" >"$STATE_FILE"
    dunstify -u low --replace=699 "󰈈 Eye Care" "Filter off"
    ;;
  warm)
    hyprsunset -t 4500 &
    echo "warm" >"$STATE_FILE"
    dunstify -u low --replace=699 "󱩌 Eye Care" "Warm — 4500K"
    ;;
  warmer)
    hyprsunset -t 3500 &
    echo "warmer" >"$STATE_FILE"
    dunstify -u low --replace=699 "󰛨 Eye Care" "Warmer — 3500K"
    ;;
  hot)
    hyprsunset -t 2700 &
    echo "hot" >"$STATE_FILE"
    dunstify -u low --replace=699 "󰈉 Eye Care" "Hot — 2700K"
    ;;
  esac
}

chosen="$(run_rofi)"
case "${chosen}" in
*"No filter"*) apply off ;;
*"4500K"*) apply warm ;;
*"3500K"*) apply warmer ;;
*"2700K"*) apply hot ;;
esac
