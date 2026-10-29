#!/bin/bash
# Throwaway Artix VM for testing the setup scripts
#
# Usage: vm.sh [base [iso] | reset | run]
#   base iso  create a fresh base disk and boot the ISO to install Artix
#   base      boot the base disk to change it (discards the overlay)
#   reset     discard the overlay and start over from the base
#   run       boot the overlay, creating it if missing
#   (none)    reset, then run
#
# Disks live in $VM_DIR (default ~/VM/Test/artix-test), the guest screen is
# $VM_RES (default 1920x1080). Inside the guest:
#   sudo mount -t 9p -o trans=virtio setup /mnt   # this repo, read-only
#   ssh -p 2222 <user>@localhost                  # from the host, needs sshd
set -euo pipefail

dir=$(dirname "$(realpath "$0")")
# shellcheck source=lib.sh
source "$dir/lib.sh"

vm=${VM_DIR:-$HOME/VM/Test/artix-test}
base=$vm/base.qcow2
base_vars=$vm/base.vars.fd
overlay=$vm/overlay.qcow2
overlay_vars=$vm/overlay.vars.fd
fw=/usr/share/edk2/x64
res=${VM_RES:-1920x1080}
[[ $res =~ ^[0-9]+x[0-9]+$ ]] || die "VM_RES must look like 1920x1080, got: $res"

usage() {
  local code=${1:-0}
  ((code == 0)) || exec >&2
  sed -n '2,14s/^# \{0,1\}//p' "$0"
  exit "$code"
}

# UEFI boot entries live in the vars file, so each disk has its own copy
boot() {
  local disk=$1 vars=$2
  shift 2
  qemu-system-x86_64 \
    -enable-kvm -machine q35 -cpu host -smp 4 -m 4G \
    -drive if=pflash,format=raw,readonly=on,file="$fw/OVMF_CODE.4m.fd" \
    -drive if=pflash,format=raw,file="$vars" \
    -drive if=virtio,format=qcow2,file="$disk" \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
    -virtfs local,path="$dir",mount_tag=setup,security_model=none,readonly=on \
    -device virtio-vga,xres="${res%x*}",yres="${res#*x}" \
    "$@"
}

reset() {
  [[ -f $base ]] || die "No base disk, run: vm.sh base <iso>"
  rm -f "$overlay"
  qemu-img create -q -f qcow2 -b "$base" -F qcow2 "$overlay"
  cp "$base_vars" "$overlay_vars"
  log "Fresh overlay on $base"
}

case ${1:-} in
base)
  # Writing to the base invalidates the overlay on top of it
  rm -f "$overlay" "$overlay_vars"
  if [[ -n ${2:-} ]]; then
    [[ -f $2 ]] || die "ISO not found: $2"
    [[ ! -f $base ]] || confirm "Replace $base?" || exit 1
    mkdir -p "$vm"
    qemu-img create -q -f qcow2 "$base" 40G
    cp "$fw/OVMF_VARS.4m.fd" "$base_vars"
    boot "$base" "$base_vars" -cdrom "$2"
  else
    [[ -f $base ]] || die "No base disk, run: vm.sh base <iso>"
    boot "$base" "$base_vars"
  fi
  ;;
reset) reset ;;
run)
  [[ -f $overlay ]] || reset
  boot "$overlay" "$overlay_vars"
  ;;
"")
  reset
  boot "$overlay" "$overlay_vars"
  ;;
-h | --help) usage ;;
*) usage 1 ;;
esac
