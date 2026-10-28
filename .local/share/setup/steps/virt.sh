# shellcheck shell=bash
# QEMU/KVM with libvirt: AppArmor confinement and the default NAT network

conf=/etc/libvirt/qemu.conf

if ! sudo grep -q '^security_driver' "$conf"; then
  line "$conf" 'security_driver = "apparmor"'
  log "Set libvirt security_driver to apparmor"
  [[ -e /run/runit/service/libvirtd ]] && sudo sv restart libvirtd
fi

if sudo virsh -c qemu:///system net-info default &>/dev/null; then
  sudo virsh -c qemu:///system net-autostart default >/dev/null
  sudo virsh -c qemu:///system net-info default | grep -q '^Active:.*yes' ||
    sudo virsh -c qemu:///system net-start default
else
  warn "libvirtd isn't running, after rebooting run: sudo virsh net-autostart default && sudo virsh net-start default"
fi
