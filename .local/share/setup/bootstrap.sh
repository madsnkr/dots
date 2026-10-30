#!/bin/bash
# Fresh-install entry point. Clones the bare dots repo into ~/.dots,
# checks it out into ~ and runs install.sh:
#
#   curl -fsSL https://raw.githubusercontent.com/madsnkr/dots/master/.local/share/setup/bootstrap.sh | bash
#
# Arguments go to install.sh: ... | bash -s -- --all
set -euo pipefail

repo=https://github.com/madsnkr/dots.git

dots() { git --git-dir="$HOME/.dots" --work-tree="$HOME" "$@"; }

[[ $EUID -ne 0 ]] || {
  echo "Run as your normal user, not root" >&2
  exit 1
}

command -v git >/dev/null || echo "Installing git" && sudo pacman -Sy --needed --noconfirm git >/dev/null

cd "$HOME"

if [[ ! -d .dots ]]; then
  echo "Cloning dotfiles repo to $HOME/.dots"
  git clone --bare "$repo" .dots &>/dev/null
  dots config --local status.showUntrackedFiles no
fi

# In the test VM, vm.sh's read-only share is mounted over the setup directory
mounted=0
mountpoint -q .local/share/setup && mounted=1

# Move files the checkout would overwrite out of the way instead of deleting them
if ! dots checkout 2>/dev/null; then
  backup="$HOME/.dots-backup/$(date +%F-%H%M%S)"
  mapfile -t files < <(dots checkout 2>&1 | awk '/^\t/ { sub(/^\t/, ""); print }')
  moved=0
  for f in "${files[@]}"; do
    ((mounted)) && [[ $f == .local/share/setup/* ]] && continue
    mkdir -p "$backup/$(dirname "$f")"
    mv "$f" "$backup/$f"
    moved=1
  done
  # Leave the mounted share out of the checkout. Only now, after the move:
  # a sparse checkout overwrites conflicting files instead of refusing
  if ((mounted)); then
    dots config core.sparseCheckout true
    printf '%s\n' '/*' '!/.local/share/setup/' >.dots/info/sparse-checkout
  fi
  dots checkout
  ((moved)) && echo "Moved conflicting files to $backup"
fi

# stdin is curl's pipe, give install.sh the terminal for prompts
exec "$HOME/.local/share/setup/install.sh" "$@" </dev/tty
