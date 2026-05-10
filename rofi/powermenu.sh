#!/usr/bin/env bash

dir="$HOME/.config/rofi"
theme='powermenu'

lastlogin="$(last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

lock=$(printf '\uf023')
sleep=$(printf ' ')
logout=$(printf '\uf08b')
reboot=$(printf '\uf021')
shutdown=$(printf '\uf011')

yes=$(printf '\uf00c')
no=$(printf '\uf00d')

rofi_cmd() {
  rofi -dmenu \
    -p "$(printf '\uf007')  $USER@$host" \
    -mesg "$(printf '\uf017')  Last Login: $lastlogin   |   $(printf '\uf2f2')  Uptime: $uptime" \
    -theme "${dir}/${theme}.rasi"
}

confirm_cmd() {
  rofi \
    -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
    -theme-str 'mainbox {children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you sure?' \
    -theme "${dir}/${theme}.rasi"
}

confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

run_rofi() {
  echo -e "$lock\n$sleep\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case $1 in
    --shutdown) systemctl poweroff ;;
    --reboot) systemctl reboot ;;
    --sleep) loginctl suspend ;;
    --logout) hyprctl dispatch exit ;;
    esac
  else
    exit 0
  fi
}

run_lock() {
  if [[ -x '/usr/bin/hyprlock' ]]; then
    hyprlock
  elif [[ -x '/usr/bin/swaylock' ]]; then
    swaylock
  elif [[ -x '/usr/bin/betterlockscreen' ]]; then
    betterlockscreen -l
  fi
}

chosen="$(run_rofi)"

case "$chosen" in
"$lock") run_lock ;;
"$sleep") run_cmd --sleep ;;
"$logout") run_cmd --logout ;;
"$reboot") run_cmd --reboot ;;
"$shutdown") run_cmd --shutdown ;;
esac
