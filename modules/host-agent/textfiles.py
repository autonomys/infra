# Writes the textfiles node_exporter reads: the disk count the server should
# have, for DiskMissing, and whether each disk /boot lives on carries GRUB's
# legacy BIOS boot code, for BootloaderMissing. A RAID 1 server can only boot
# from the surviving disk if that disk has the code in its first sector, and
# copying a partition table or rebuilding an array doesn't put it there.
import os
import time

TEXTFILE_DIR = "/textfiles"
INTERVAL_SECONDS = 6 * 3600
# GRUB 2's boot.img holds "GRUB" among its error strings; the partition table
# starts at byte 446, so the code fits in the first 440
BOOT_CODE_BYTES = 440
HOST_BOOT = "/proc/1/root/boot"


def write_textfile(name, text):
    path = f"{TEXTFILE_DIR}/{name}"
    with open(f"{path}.tmp", "w") as f:
        f.write(text)
    os.rename(f"{path}.tmp", path)


def block_name(dev):
    path = f"/sys/dev/block/{os.major(dev)}:{os.minor(dev)}"
    if not os.path.exists(path):
        raise RuntimeError(f"/boot is on device {os.major(dev)}:{os.minor(dev)}, which isn't a block device")
    return os.path.basename(os.path.realpath(path))


def disks_under(name):
    """The whole disks a block device is built from: an array's or volume's
    members, resolved down to the disks their partitions are on."""
    slaves = f"/sys/class/block/{name}/slaves"
    members = os.listdir(slaves) if os.path.isdir(slaves) else []
    if members:
        return sorted({d for m in members for d in disks_under(m)})
    if os.path.exists(f"/sys/class/block/{name}/partition"):
        return [os.path.basename(os.path.dirname(os.path.realpath(f"/sys/class/block/{name}")))]
    return [name]


def has_grub(disk):
    with open(f"/dev/{disk}", "rb") as f:
        return b"GRUB" in f.read(BOOT_CODE_BYTES)


def disks_expected():
    return (
        "# HELP node_disks_expected How many disks this server should have.\n"
        "# TYPE node_disks_expected gauge\n"
        f"node_disks_expected {int(os.environ['EXPECTED_DISKS'])}\n"
    )


def bootloader():
    uefi = os.path.isdir("/sys/firmware/efi")
    lines = [
        "# HELP node_boot_efi Whether the server booted through UEFI (1) or legacy BIOS (0).",
        "# TYPE node_boot_efi gauge",
        f"node_boot_efi {int(uefi)}",
    ]
    if not uefi:
        lines += [
            "# HELP node_bootloader_grub_present Whether a disk /boot lives on has GRUB's legacy BIOS boot code in its first sector.",
            "# TYPE node_bootloader_grub_present gauge",
        ]
        for disk in disks_under(block_name(os.stat(HOST_BOOT).st_dev)):
            lines.append(f'node_bootloader_grub_present{{device="{disk}"}} {int(has_grub(disk))}')
    return "\n".join(lines) + "\n"


while True:
    for name, render in (("disks.prom", disks_expected), ("bootloader.prom", bootloader)):
        try:
            write_textfile(name, render())
        except Exception as e:
            # A stale file trips the healthcheck and BootloaderCheckStale
            print(f"writing {name} failed: {type(e).__name__}: {e}", flush=True)
    time.sleep(INTERVAL_SECONDS)
