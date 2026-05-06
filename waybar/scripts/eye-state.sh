#!/bin/bash
STATE_FILE="/tmp/hyprsunset_state"
state=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

case "$state" in
  warm)   echo '{"text":"󱩌","class":"warm","tooltip":"Warm (4500K)"}' ;;
  warmer) echo '{"text":"󰛨","class":"warmer","tooltip":"Warmer (3500K)"}' ;;
  hot)    echo '{"text":"󰈉","class":"hot","tooltip":"Hot (2700K)"}' ;;
  *)      echo '{"text":"󰈈","class":"off","tooltip":"Eye care: Off"}' ;;
esac
