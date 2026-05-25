#!/usr/bin/env bash
dir="$HOME/.config/rofi"
theme='powermenu'

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Options — icon + label, no duplication
shutdown="<span font='18'>󰀑</span>  Shutdown"
reboot="<span font='18'>󰜉</span>  Reboot"
lock="<span font='18'>󰌾</span>  Lock"
suspend="<span font='18'>󰤄</span>  Suspend"
logout="<span font='18'>󰍃</span>  Logout"
hibernate="<span font='18'>󰒲</span>  Hibernate"
yes="<span font='18'>󰄬</span>  Yes"
no="<span font='18'>󰅖</span>  No"

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "  $USER@$host" \
    -mesg "  Uptime: $uptime" \
    -markup-rows \
    -theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
  rofi \
    -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
    -theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you Sure?' \
    -markup-rows \
    -theme "${dir}/${theme}.rasi"
}

confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case $1 in
    --shutdown) systemctl poweroff ;;
    --reboot) systemctl reboot ;;
    --hibernate) systemctl hibernate ;;
    --suspend) systemctl suspend ;;
    --logout) hyprctl dispatch exit ;;
    esac
  else
    exit 0
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
*Shutdown*) run_cmd --shutdown ;;
*Reboot*) run_cmd --reboot ;;
*Hibernate*) run_cmd --hibernate ;;
*Lock*) hyprlock ;;
*Suspend*) run_cmd --suspend ;;
*Logout*) run_cmd --logout ;;
esac
