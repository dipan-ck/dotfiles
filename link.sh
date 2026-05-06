#!/bin/bash

DOTFILES_DIR="$HOME/dev/dotfile"
CONFIG_DIR="$HOME/.config"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

configs=(
  "hypr"
  "kitty"
  "matugen"
  "quickshell"
  "btop"
  "rofi"
  "nvim"
  "gtk-3.0"
  "gtk-4.0"
  "wall"
  "rofi"
  "waybar"
  "swaync"
)

echo "Syncing from $CONFIG_DIR to $DOTFILES_DIR"
echo "------------------------------------------"

for config in "${configs[@]}"; do
  src="$CONFIG_DIR/$config"
  dest="$DOTFILES_DIR/$config"

  # Skip if source doesn't exist in .config
  if [ ! -e "$src" ]; then
    echo -e "${YELLOW}SKIP${NC}   $config  (not found in .config)"
    continue
  fi

  # Remove old copy in dotfiles dir
  rm -rf "$dest"

  # Copy fresh from .config
  cp -r "$src" "$dest"
  echo -e "${GREEN}SYNCED${NC} $config  → $dest"
done

echo "Done! All configs Synced"
