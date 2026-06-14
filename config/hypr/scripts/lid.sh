#!/usr/bin/env sh

# External monitor connected?
if hyprctl monitors | grep -q 'HDMI-A-1'; then

  if [ "$1" = "close" ]; then
    # Disable laptop screen
    hyprctl keyword monitor "eDP-1,disable"

  elif [ "$1" = "open" ]; then
    # Restore laptop screen
    hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
  fi

elif [ "$1" = "open" ]; then
  # Always restore laptop screen when opening the lid,
  # even if HDMI isn't connected.
  hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
fi
