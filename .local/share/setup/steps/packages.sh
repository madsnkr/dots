# shellcheck shell=bash
# Core packages, microcode and GPU drivers (+ full package lists with --all)

mapfile -t core < <(list "$dir/core.txt")

case $(grep -m1 vendor_id /proc/cpuinfo) in
*GenuineIntel*) core+=(intel-ucode) ;;
*AuthenticAMD*) core+=(amd-ucode) ;;
esac

# Display controllers have PCI class 0x03xxxx
for dev in /sys/bus/pci/devices/*; do
	[[ $(<"$dev/class") == 0x03* ]] || continue
	case $(<"$dev/vendor") in
	0x8086) core+=(intel-media-driver vpl-gpu-rt vulkan-intel) ;;
	0x1002) core+=(vulkan-radeon) ;;
	0x10de) core+=(nvidia-open-dkms nvidia-utils) ;;
	esac
done

pkgs "${core[@]}"

mapfile -t extra < <(list "$dir/core-aur.txt")
((${#extra[@]})) && aur "${extra[@]}"

if ((ALL)); then
	lists=("$HOME/.local/share/pacman/official.txt" "$HOME/.local/share/pacman/aur.txt")
	for f in "${lists[@]}"; do
		[[ -f $f ]] || die "$f missing, check out the dots repo first"
	done
	mapfile -t all < <(list "${lists[@]}")
	aur "${all[@]}"
fi
