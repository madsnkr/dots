# shellcheck shell=bash
# Helpers shared by install.sh and the steps

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mxx\033[0m %s\n' "$*" >&2
  exit 1
}

confirm() {
  read -rp "$1 [y/N] " yn
  [[ $yn == [Yy]* ]]
}

dots() { git --git-dir="$HOME/.dots" --work-tree="$HOME" "$@"; }

# Print package names from list files, without comments and blank lines
list() { sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$@"; }

# Install official packages. --ask 4 lets pacman replace conflicting
# packages (e.g. iptables -> iptables-nft), which --noconfirm refuses
pkgs() { sudo pacman -S --needed --noconfirm --ask 4 "$@"; }

# Install packages from the official repos or the AUR
aur() { yay -S --needed --noconfirm --ask 4 "$@"; }

# Enable runit services. Linking into runsvdir/default works both on a
# running system and from a chroot during install
svc() {
  local s
  for s; do
    if [[ ! -d /etc/runit/sv/$s ]]; then
      warn "service $s not installed, skipping"
    elif [[ ! -e /etc/runit/runsvdir/default/$s ]]; then
      sudo ln -s "/etc/runit/sv/$s" /etc/runit/runsvdir/default/
      log "Enabled $s"
    fi
  done
}

# Append a line to a root-owned file unless it's already there
line() {
  sudo grep -qxF -- "$2" "$1" 2>/dev/null ||
    echo "$2" | sudo tee -a "$1" >/dev/null
}
