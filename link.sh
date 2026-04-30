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
)

echo "Creating symlinks from $DOTFILES_DIR to $CONFIG_DIR"
echo "----------------------------------------------------"

for config in "${configs[@]}"; do
  src="$DOTFILES_DIR/$config"
  dest="$CONFIG_DIR/$config"

  # Skip if source doesn't exist in dotfiles yet
  if [ ! -e "$src" ]; then
    echo -e "${YELLOW}SKIP${NC}   $config  (not found in dotfiles dir)"
    continue
  fi

  # Backup if destination exists and is NOT already a symlink
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo -e "${YELLOW}BACKUP${NC} $config  → $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  # Remove existing symlink if broken or outdated
  if [ -L "$dest" ]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo -e "${GREEN}LINKED${NC} $config  → $dest"
done

echo ""
echo "Done! Verify with: ls -la ~/.config"
