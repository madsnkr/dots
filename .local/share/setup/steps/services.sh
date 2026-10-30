# shellcheck shell=bash
# runit services. runsvdir starts them within a few seconds of being linked

svc dbus elogind udevd \
	NetworkManager openntpd firewalld \
	cronie bluetoothd auditd \
	docker libvirtd virtlogd virtlockd
