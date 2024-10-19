#!/bin/sh

lockfile="/tmp/waybar_updates.lock"

(
  # This is needed because the script is ran for each monitor, so we need to prevent the race condition
  flock 9 # Acquire lock

  official=$(checkupdates 2>/dev/null | wc -l)
  aur=$(yay -Qua | wc -l)

  updates=$((official + aur))

  if [ "$updates" -eq 0 ]; then
    output="󱝍"
  elif [ "$updates" -eq 1 ]; then
    test "$official" -eq 1 && output="1 Official 󱓽" || output="1 AUR 󱓽"
  else
    output="󱓽 Official $official 󱓾 AUR $aur"
  fi

  echo "$output"

) 9>"$lockfile"
