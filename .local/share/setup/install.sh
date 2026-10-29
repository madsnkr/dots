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

# Only messages go to the terminal, command output goes to the log
LOG=${XDG_STATE_HOME:-$HOME/.local/state}/setup/install-$(date +%F-%H%M%S).log
mkdir -p "${LOG%/*}"
exec >>"$LOG" 2>&1
log "Logging to $LOG (tail -f it to follow along)"

nopasswd=
finish() {
  local code=$?
  if ((code)); then
    tail -n 20 "$LOG" | sed 's/^/   /' >&4
    warn "Failed, full log: $LOG"
  fi
  [[ -z $nopasswd ]] || sudo rm -f "$nopasswd"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Ask for the password once. A cached sudo login can expire or be asked
# for again by makepkg and yay during long builds, so allow passwordless
# sudo until we exit. zz sorts last, so it wins over 10-wheel
sudo -v || die "sudo is required"
tmp=$(mktemp)
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" >"$tmp"
sudo visudo -cqf "$tmp" || die "Couldn't validate the temporary sudoers rule"
sudo install -m 0440 "$tmp" /etc/sudoers.d/zz-install
nopasswd=/etc/sudoers.d/zz-install
rm -f "$tmp"

REBOOT_NEEDED=0

# Run the selected steps in their fixed order
for step in "${steps[@]}"; do
  [[ " ${selected[*]} " == *" $step "* ]] || continue
  log "Step: $step"
  # shellcheck source=/dev/null
  source "$dir/steps/$step.sh"
done

log "Done, log: $LOG"
((REBOOT_NEEDED)) && warn "Reboot to finish (kernel parameters, groups, services)"
exit 0
