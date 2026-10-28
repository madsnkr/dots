# shellcheck shell=bash
# Kernel parameters for AppArmor and auditing

params="audit=1 lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
grub=/etc/default/grub

if [[ ! -f $grub ]]; then
	warn "GRUB not found, add these kernel parameters yourself: $params"
elif ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*apparmor' "$grub"; then
	log "Adding AppArmor kernel parameters"
	sudo sed -i.bak "/^GRUB_CMDLINE_LINUX_DEFAULT=/s|\"$| $params\"|" "$grub"
	grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*apparmor' "$grub" ||
		die "Couldn't edit GRUB_CMDLINE_LINUX_DEFAULT in $grub, add: $params"
	sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

aa-enabled -q 2>/dev/null || REBOOT_NEEDED=1
