#!/bin/bash
# Set up an Artix (runit) system. Safe to re-run.
#
# Usage: install.sh [--all] [step...]
#   --all   also install ~/.local/share/pacman/{official,aur}.txt
#   step    any of the steps below; no steps runs them all
#
# Needs a normal user with sudo rights.
set -euo pipefail

dir=$(dirname "$(realpath "$0")")
# shellcheck source=lib.sh
source "$dir/lib.sh"

steps=(repos packages user services apparmor libvirt virt)

usage() {
  local code=${1:-0}
  # Help on request goes to stdout, help after an error to stderr
  ((code == 0)) || exec >&2
  sed -n '2,8s/^# \{0,1\}//p' "$0"
  echo "Steps: ${steps[*]}"
  exit "$code"
}

ALL=0
selected=()
for arg; do
  case $arg in
  --all) ALL=1 ;;
  -h | --help) usage ;;
  *)
    [[ " ${steps[*]} " == *" $arg "* ]] || {
      warn "unknown step: $arg"
      usage 1
    }
    selected+=("$arg")
    ;;
  esac
done
((${#selected[@]})) || selected=("${steps[@]}")

[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (makepkg refuses root)"

# Ask for the password once and keep sudo alive until we exit
sudo -v || die "sudo is required"
while sleep 50; do sudo -n true; done 2>/dev/null &
keepalive=$!
trap 'kill "$keepalive" 2>/dev/null' EXIT

REBOOT_NEEDED=0

# Run the selected steps in their fixed order
for step in "${steps[@]}"; do
  [[ " ${selected[*]} " == *" $step "* ]] || continue
  log "Step: $step"
  # shellcheck source=/dev/null
  source "$dir/steps/$step.sh"
done

log "Done"
((REBOOT_NEEDED)) && warn "Reboot to finish (kernel parameters, groups, services)"
exit 0
