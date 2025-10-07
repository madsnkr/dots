#!/bin/sh

# Check if navi window exists
if hyprctl clients | grep -q "title: navi"; then
  # Close it
  hyprctl dispatch closewindow "title:^(navi)$"
else
  # Launch new instance
  navi --print | wl-copy
fi
