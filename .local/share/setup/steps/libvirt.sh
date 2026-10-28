# shellcheck shell=bash
# The libvirt package is built without AppArmor. Rebuild it with the
# AppArmor security driver and profiles, and keep pacman from replacing it.
# Re-run `install.sh libvirt` to rebuild against a newer PKGBUILD.

src="$HOME/Repos/gitea.artixlinux.org/libvirt"

if [[ -d $src/.git ]]; then
	git -C "$src" checkout -- PKGBUILD # drop the last run's edits
	git -C "$src" pull --ff-only
else
	git clone https://gitea.artixlinux.org/packages/libvirt.git "$src" ||
		die "Couldn't clone libvirt (gitea.artixlinux.org may be down, try again later)"
fi

cd "$src"

srcinfo=$(makepkg --printsrcinfo)
want=$(awk '$1 == "epoch" { e = $3 ":" } $1 == "pkgver" { v = $3 } $1 == "pkgrel" { r = $3 }
	END { print e v "-" r }' <<<"$srcinfo")
have=$(pacman -Q libvirt 2>/dev/null | cut -d' ' -f2)

if [[ $have == "$want" ]] && pacman -Qi libvirt | grep -q '^Depends On.*apparmor'; then
	log "libvirt $have is already built with AppArmor"
else
	log "Building libvirt $want with AppArmor"
	sed -i -e 's/-D\(apparmor\|apparmor_profiles\|secdriver_apparmor\)=disabled/-D\1=enabled/' \
		-e 's/^depends=(/depends=(apparmor /' \
		-e 's/^makedepends=(/makedepends=(apparmor /' PKGBUILD
	[[ $(grep -c -- '-D\(apparmor\|apparmor_profiles\|secdriver_apparmor\)=enabled' PKGBUILD) -eq 3 ]] ||
		die "PKGBUILD has changed, couldn't enable AppArmor in $src/PKGBUILD"

	awk '$1 == "validpgpkeys" { print $3 }' <<<"$srcinfo" | while read -r key; do
		gpg --list-keys "$key" &>/dev/null || gpg --recv-keys "$key"
	done

	# Tests are slow and flaky, -f rebuilds an existing package file
	makepkg -sif --noconfirm --skipchecks
fi

if ! grep -qE '^IgnorePkg.*\blibvirt\b' /etc/pacman.conf; then
	if grep -q '^IgnorePkg' /etc/pacman.conf; then
		sudo sed -i '/^IgnorePkg/s/$/ libvirt/' /etc/pacman.conf
	else
		sudo sed -i '/^\[options\]/a IgnorePkg = libvirt' /etc/pacman.conf
	fi
	log "Added libvirt to IgnorePkg"
fi
