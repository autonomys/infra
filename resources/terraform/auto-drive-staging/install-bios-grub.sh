#!/bin/bash

# Installs legacy-BIOS GRUB on every disk under the /boot mirror, and has the
# grub-pc package keep all of them current on future GRUB updates. Run once as
# root right after first boot, before first-boot.sh; safe to re-run:
#
#   curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/install-bios-grub.sh -o install-bios-grub.sh
#   bash install-bios-grub.sh
#
# The provider's Ubuntu image installs the UEFI GRUB package even on BIOS boxes.
# Its updates never refresh the BIOS boot code, and the box then boots from
# whichever disk installimage happened to write, until it doesn't.

set -euo pipefail

BIOS_BOOT_GUID=21686148-6449-6e6f-744e-656564454649

fail() {
  echo "$*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || fail "Run this as root."
[ ! -d /sys/firmware/efi ] || fail "This box booted via UEFI; this script is for legacy BIOS boxes."

boot_md="$(readlink -f "$(findmnt -no SOURCE /boot)")"
[[ "$boot_md" == /dev/md* ]] || fail "/boot is on $boot_md, not an md RAID array."

disks=()
for member in /sys/block/"$(basename "$boot_md")"/slaves/*; do
  disk="/dev/$(lsblk -dno PKNAME "/dev/$(basename "$member")")"
  [ -b "$disk" ] && [ "$(lsblk -dno TYPE "$disk")" = disk ] \
    || fail "Could not resolve the disk under /boot member $(basename "$member"): got '$disk'."
  disks+=("$disk")
done
[ "${#disks[@]}" -ge 2 ] || fail "/boot is not mirrored: members are ${disks[*]}."

for disk in "${disks[@]}"; do
  if [ "$(lsblk -dno PTTYPE "$disk")" = gpt ] \
    && ! lsblk -no PARTTYPE "$disk" | grep -qi "$BIOS_BOOT_GUID"; then
    fail "$disk has a GPT label but no BIOS boot partition, so GRUB has nowhere to embed its core image."
  fi
done

# debconf wants stable names, so a renumbered disk still gets updates
stable_name() {
  local link
  for link in /dev/disk/by-id/*; do
    case "$link" in *-part* | */nvme-eui.* | */wwn-*) continue ;; esac
    if [ "$(readlink -f "$link")" = "$1" ]; then
      echo "$link"
      return
    fi
  done
  echo "$1"
}

install_devices=()
for disk in "${disks[@]}"; do install_devices+=("$(stable_name "$disk")"); done
selection="$(printf '%s, ' "${install_devices[@]}")"
selection="${selection%, }"

echo "==> GRUB install devices: $selection"
debconf-set-selections <<EOF
grub-pc grub-pc/install_devices multiselect $selection
grub-pc grub-pc/install_devices_empty boolean false
EOF

export DEBIAN_FRONTEND=noninteractive
echo "==> Installing grub-pc, which replaces the UEFI grub package if present"
apt-get update -y
apt-get install -y grub-pc

for disk in "${disks[@]}"; do
  echo "==> grub-install --target=i386-pc $disk"
  grub-install --target=i386-pc --recheck "$disk"
done
update-grub

for disk in "${disks[@]}"; do
  dd if="$disk" bs=512 count=1 status=none | grep -aq GRUB \
    || fail "No GRUB boot code in the first sector of $disk after installing."
  echo "==> $disk carries GRUB boot code"
done

echo "==> grub-pc will reinstall to: $(debconf-show grub-pc | sed -n 's/.*grub-pc\/install_devices: //p')"
