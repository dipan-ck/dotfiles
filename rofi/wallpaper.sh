#!/usr/bin/env bash

WALL_DIR="$HOME/.config/wall"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
ROFI_CACHE="$HOME/.config/rofi/current_wallpaper"

# Build the list of wallpapers as display entries with icon paths
wall_list=""
while IFS= read -r -d '' file; do
  name=$(basename "$file")
  wall_list+="$name\x00icon\x1f$file\n"
done < <(find "$WALL_DIR" -maxdepth 1 -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" \
  -o -iname "*.png" -o -iname "*.webp" \
  -o -iname "*.gif" \) -print0 | sort -z)

chosen=$(printf "%b" "$wall_list" | rofi \
  -dmenu \
  -p "Wallpaper" \
  -show-icons \
  -theme "$ROFI_THEME")

[[ -z "$chosen" ]] && exit 0

chosen_path="$WALL_DIR/$chosen"

# ── Apply wallpaper via awww ──────────────────────────────────────────────────
awww img "$chosen_path" \
  --transition-type grow \
  --transition-pos center \
  --transition-duration 1.5 \
  --transition-fps 60

# ── Update rofi wallpaper cache ───────────────────────────────────────────────
cp "$chosen_path" "$ROFI_CACHE"

# ── Matugen: detect saturation then run correct scheme ───────────────────────
sat=$(convert "$chosen_path" \
  -colorspace HSL \
  -channel Saturation \
  -separate \
  -format "%[fx:mean*100]\n" \
  info: 2>/dev/null || echo 50)

if (($(echo "$sat < 5.0" | bc -l))); then
  scheme="scheme-monochrome"
else
  scheme="scheme-fidelity"
fi

matugen image \
  --prefer darkness \
  --type "$scheme" \
  "$chosen_path"

# ── Notify ────────────────────────────────────────────────────────────────────
notify-send "Wallpaper Applied" "$chosen\nColor scheme regenerated"
