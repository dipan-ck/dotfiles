#!/usr/bin/env bash
## Applets : Screenshot (Hyprland — hyprshot + satty)

ROFI_DIR="$HOME/.config/rofi"
THEME="$ROFI_DIR/screenshot.rasi"

prompt='Screenshot'
dir="$(xdg-user-dir PICTURES)/Screenshots"
mesg="DIR: $dir"

option_1="<span font='18'>󰹑</span>  Capture Desktop"
option_2="<span font='18'>󰩭</span>  Capture Area"
option_3="<span font='18'>󱂬</span>  Capture Window"
option_4="<span font='18'>󱎫</span>  Capture in 5s"
option_5="<span font='18'>󱎫</span>  Capture in 10s"

rofi_cmd() {
  rofi \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "$THEME"
}

run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

[[ ! -d "$dir" ]] && mkdir -p "$dir"

# Notify helper
notify_saved() {
  local f="$1"
  dunstify -u low --replace=699 \
    -i "$f" \
    "Screenshot saved" \
    "$(basename "$f")"
}

# countdown
countdown() {
  for sec in $(seq "$1" -1 1); do
    dunstify -t 1000 --replace=699 "Taking shot in : $sec"
    sleep 1
  done
}

# Shot functions — capture then open in satty for annotation
shotnow() {
  sleep 0.5
  hyprshot -m output --raw | satty --filename - --output-filename "$dir/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
  notify_saved "$(ls -t "$dir"/*.png 2>/dev/null | head -1)"
}

shotarea() {
  hyprshot -m region --raw | satty --filename - --output-filename "$dir/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
  notify_saved "$(ls -t "$dir"/*.png 2>/dev/null | head -1)"
}

shotwin() {
  hyprshot -m window --raw | satty --filename - --output-filename "$dir/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
  notify_saved "$(ls -t "$dir"/*.png 2>/dev/null | head -1)"
}

shot5() {
  countdown 5
  sleep 1
  shotnow
}

shot10() {
  countdown 10
  sleep 1
  shotnow
}

run_cmd() {
  case "$1" in
  --opt1) shotnow ;;
  --opt2) shotarea ;;
  --opt3) shotwin ;;
  --opt4) shot5 ;;
  --opt5) shot10 ;;
  esac
}

chosen="$(run_rofi)"
case "${chosen}" in
"$option_1") run_cmd --opt1 ;;
"$option_2") run_cmd --opt2 ;;
"$option_3") run_cmd --opt3 ;;
"$option_4") run_cmd --opt4 ;;
"$option_5") run_cmd --opt5 ;;
esac
