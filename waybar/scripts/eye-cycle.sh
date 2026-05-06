#!/bin/bash
STATE_FILE="/tmp/hyprsunset_state"
state=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

pkill hyprsunset 2>/dev/null
sleep 0.1

case "$state" in
  off)
    hyprsunset -t 4500 &
    echo "warm" > "$STATE_FILE"
    ;;
  warm)
    hyprsunset -t 3500 &
    echo "warmer" > "$STATE_FILE"
    ;;
  warmer)
    hyprsunset -t 2700 &
    echo "hot" > "$STATE_FILE"
    ;;
  hot)
    echo "off" > "$STATE_FILE"
    ;;
esac
