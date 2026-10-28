# shellcheck shell=bash
# Arch repos on Artix, pacman options and yay

conf=/etc/pacman.conf

sudo pacman -S --needed --noconfirm artix-archlinux-support git base-devel

for repo in extra multilib; do
	if ! grep -q "^\[$repo\]" "$conf"; then
		printf '\n[%s]\nInclude = /etc/pacman.d/mirrorlist-arch\n' "$repo" | sudo tee -a "$conf" >/dev/null
		log "Added [$repo]"
	fi
done

sudo sed -i -e 's/^#Color/Color/' -e 's/^#ParallelDownloads/ParallelDownloads/' "$conf"

sudo pacman -Syu --noconfirm

# Build yay as its README describes (git and base-devel are installed above)
if ! command -v yay >/dev/null; then
	log "Installing yay"
	tmp=$(mktemp -d)
	git clone https://aur.archlinux.org/yay.git "$tmp/yay"
	(cd "$tmp/yay" && makepkg -si --noconfirm)
	rm -rf "$tmp"
fi
