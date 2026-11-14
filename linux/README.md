# Redmi 9A native Linux bring-up

The first-boot initramfs mounts the phone's microSD partition `/dev/mmcblk1p1`
as FAT32, attaches `/linux-rootfs.ext4` as a loop device, mounts that ext4
filesystem, then starts `/sbin/init` from it. The ext4 image must be smaller
than 4 GiB because the current card is FAT32. The current rootfs is the 512 MiB
Alpine image from Alpican 4.1.

Build the initramfs with:

```bash
bash build-tools/build_linux_ramdisk.sh
```

The builder extracts the rootfs's ARM64 BusyBox and musl loader with `debugfs`,
so the initramfs uses the same userspace as the rootfs.

The generated archive is `out-linux/initramfs.cpio.gz`. The boot image still
can be repacked with the Linux kernel and this ramdisk using the stock boot
image as a metadata/DTB source:

```bash
bash build-tools/package_linux_boot.sh /path/to/stock-boot.img
```

The result is `out-linux/boot-linux.img`. The packaging step keeps the stock
header addresses and board DTB, preserves the stock command line arguments,
then sets `init=/init` and enables kernel log output. It only creates a local
file; it does not flash the phone. Copy `out-linux/linux-rootfs.ext4` to the microSD root as
`linux-rootfs.ext4` before a boot attempt. This setup does not format or
repartition the card.

## Wireless adapters

The native Linux defconfig enables the MT6765 combo Wi-Fi/Bluetooth drivers
used by the phone. It also enables the in-tree RTL8812BU/RTL8822BU USB Wi-Fi
driver, including TP-Link `2357:0115` adapters such as the Archer T4U V3.
USB Bluetooth uses `btusb`; this tree includes support for the TP-Link UB500
(`2357:0604`, Realtek RTL8761BU).

Install the Bluetooth firmware in Alpine's root filesystem before using the
UB500:

```sh
apk add linux-firmware-rtl_bt
```

The kernel loads `rtl_bt/rtl8761bu_fw.bin` and
`rtl_bt/rtl8761bu_config.bin` from `/lib/firmware`. These are userspace
firmware files and are not embedded in the kernel image.
