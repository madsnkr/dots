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

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root" >&2; exit 1; }
command -v git >/dev/null || sudo pacman -S --needed --noconfirm git

cd "$HOME"

if [[ ! -d .dots ]]; then
	git clone --bare "$repo" .dots
	dots config --local status.showUntrackedFiles no
fi

# Move files the checkout would overwrite out of the way instead of deleting them
if ! dots checkout 2>/dev/null; then
	backup="$HOME/.dots-backup/$(date +%F-%H%M%S)"
	mapfile -t files < <(dots checkout 2>&1 | awk '/^\t/ { sub(/^\t/, ""); print }')
	for f in "${files[@]}"; do
		mkdir -p "$backup/$(dirname "$f")"
		mv "$f" "$backup/$f"
	done
	dots checkout
	echo "Moved conflicting files to $backup"
fi

# stdin is curl's pipe, give install.sh the terminal for prompts
exec "$HOME/.local/share/setup/install.sh" "$@" </dev/tty
