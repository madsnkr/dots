# shellcheck shell=bash
# Groups, sudo, login shell and home directories

# Groups that don't exist yet come with their package
for group in wheel video kvm libvirt docker log wireshark; do
	getent group "$group" >/dev/null || continue
	id -nG "$USER" | grep -qw "$group" || {
		sudo usermod -aG "$group" "$USER"
		log "Added $USER to $group"
		REBOOT_NEEDED=1
	}
done

if [[ ! -f /etc/sudoers.d/10-wheel ]]; then
	tmp=$(mktemp)
	echo '%wheel ALL=(ALL:ALL) ALL' >"$tmp"
	sudo visudo -cqf "$tmp" && sudo install -m 0440 "$tmp" /etc/sudoers.d/10-wheel
	rm -f "$tmp"
fi

[[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]] || sudo chsh -s /bin/zsh "$USER"

xdg-user-dirs-update

if ! git config --global user.name >/dev/null || ! git config --global user.email >/dev/null; then
	warn "git user.name/user.email not set (git config --global user.name ...)"
fi
