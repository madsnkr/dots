#!/usr/bin/env bash

choice=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | fuzzel --dmenu)

if [[ $choice == "Lock" ]]; then
  bash ~/.config/system_scripts/wayland_session_lock
elif [[ $choice == "Logout" ]]; then
  pkill -KILL -u "$USER"
elif [[ $choice == "Suspend" ]]; then
  loginctl suspend
elif [[ $choice == "Reboot" ]]; then
  loginctl reboot
elif [[ $choice == "Shutdown" ]]; then
  loginctl poweroff
fi
