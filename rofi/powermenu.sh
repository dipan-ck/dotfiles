#!/usr/bin/env bash

dir="$HOME/.config/rofi"
theme='powermenu'

lastlogin="$(last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Font Awesome codepoints — safe range, always in JetBrains Mono Nerd Font
lock=$(printf '\uf023')      # fa-lock
suspend=$(printf '\uf186')   # fa-moon-o
logout=$(printf '\uf08b')    # fa-sign-out
hibernate=$(printf '\uf236') # fa-bed
reboot=$(printf '\uf021')    # fa-refresh
shutdown=$(printf '\uf011')  # fa-power-off
yes=$(printf '\uf00c')       # fa-check
no=$(printf '\uf00d')        # fa-times

rofi_cmd() {
  rofi -dmenu \
    -p "$(printf '\uf007') $USER@$host" \
    -mesg "$(printf '\uf017') Last Login: $lastlogin  |  $(printf '\uf021') Uptime: $uptime" \
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
    -mesg 'Are you Sure?' \
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
case ${chosen} in
"$shutdown") run_cmd --shutdown ;;
"$reboot") run_cmd --reboot ;;
"$hibernate") run_cmd --hibernate ;;
"$lock") run_lock ;;
"$suspend") run_cmd --suspend ;;
"$logout") run_cmd --logout ;;
esac
