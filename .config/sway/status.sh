#!/bin/sh
# Status line for swaybar: battery + date/time, refreshed every second.
bat=/sys/class/power_supply/BAT0
while :; do
    echo "BAT $(cat "$bat/capacity")% ($(cat "$bat/status")) | $(date +'%Y-%m-%d %X')"
    sleep 1
done
