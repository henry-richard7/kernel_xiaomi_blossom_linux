#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out-linux"
DEFAULT_STOCK="/home/henry/Redmi-9A-Mods/Backups/stock-boot.img"
STOCK_BOOT="${1:-${DEFAULT_STOCK}}"
OUTPUT_IMAGE="${2:-${OUT_DIR}/boot-linux.img}"

[[ -f "${OUT_DIR}/arch/arm64/boot/Image.gz" ]] || {
	echo "Missing Linux kernel image; run build-tools/compile_linux.sh first." >&2
	exit 1
}
[[ -f "${OUT_DIR}/initramfs.cpio.gz" ]] || {
	echo "Missing Linux initramfs; run build-tools/build_linux_ramdisk.sh first." >&2
	exit 1
}

mkdir -p "$(dirname "${OUTPUT_IMAGE}")"
STOCK_DTB="${OUT_DIR}/stock-boot.dtb"
BOOT_METADATA="${OUT_DIR}/stock-boot-metadata.txt"

if [ -f "${STOCK_DTB}" ] && [ -f "${BOOT_METADATA}" ]; then
	echo "[*] Using cached stock DTB and metadata from ${OUT_DIR}"
elif [ -f "${STOCK_BOOT}" ]; then
	echo "[*] Extracting stock DTB and metadata from ${STOCK_BOOT}"
	python3 - "${STOCK_BOOT}" "${STOCK_DTB}" "${BOOT_METADATA}" <<'PY'
import struct
import re
import sys

boot_path, dtb_path, metadata_path = sys.argv[1:]
with open(boot_path, "rb") as f:

    def read_at(offset, size):
        f.seek(offset)
        data = f.read(size)
        if len(data) != size:
            raise SystemExit(f"Truncated boot image while reading offset {offset}")
        return data

    if read_at(0, 8) != b"ANDROID!":
        raise SystemExit("Input is not an Android boot image")

    values = struct.unpack("<10I", read_at(8, 40))
    kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size, second_addr, tags_addr, page_size, header_version, os_version = values
    if header_version != 2 or page_size != 2048:
        raise SystemExit(f"Expected boot header v2/page size 2048; got v{header_version}/{page_size}")

    recovery_dtbo_size = struct.unpack("<I", read_at(1632, 4))[0]
    recovery_dtbo_offset = struct.unpack("<Q", read_at(1636, 8))[0]
    dtb_size = struct.unpack("<I", read_at(1648, 4))[0]
    if not dtb_size:
        raise SystemExit("Stock boot image has no embedded DTB")

    align = lambda n: (n + page_size - 1) & ~(page_size - 1)
    kernel_offset = page_size
    ramdisk_offset = kernel_offset + align(kernel_size)
    second_offset = ramdisk_offset + align(ramdisk_size)
    recovery_offset = recovery_dtbo_offset or (second_offset + align(second_size))
    dtb_offset = align(recovery_offset + recovery_dtbo_size)
    dtb = read_at(dtb_offset, dtb_size)
    if dtb[:4] != b"\xd0\x0d\xfe\xed":
        raise SystemExit(f"Embedded DTB magic missing at calculated offset {dtb_offset}")
    with open(dtb_path, "wb") as out:
        out.write(dtb)

with open(boot_path, "rb") as f:
    f.seek(64)
    cmdline = f.read(512).split(b"\0", 1)[0]
    f.seek(608)
    cmdline += b" " + f.read(1024).split(b"\0", 1)[0]
cmdline = b" ".join(cmdline.split()).decode("ascii")
cmdline = re.sub(r"(?:^| )quiet(?: |$)", " ", cmdline)
cmdline = re.sub(r"(?:^| )loglevel=\S+", "", cmdline)
cmdline = " ".join(cmdline.split()) + " console=ttyS0,921600n1 console=ttyGS0,115200n8 init=/init loglevel=4 printk.time=1"
major, minor, patch = (os_version >> 25) & 0x7f, (os_version >> 18) & 0x7f, (os_version >> 11) & 0x7f
year, month = 2000 + ((os_version >> 4) & 0x7f), os_version & 0xf
with open(metadata_path, "w", encoding="utf-8") as out:
    out.write(f"{cmdline}\n{kernel_addr:#x}\n{ramdisk_addr:#x}\n{tags_addr:#x}\n")
    out.write(f"{major}.{minor}.{patch}\n{year:04d}-{month:02d}\n")
print(f"Extracted stock DTB ({dtb_size} bytes) from offset {dtb_offset}")
PY
else
	echo "Stock boot image not found at: ${STOCK_BOOT} and no cached DTB in ${OUT_DIR}" >&2
	exit 1
fi

mapfile -t META < "${BOOT_METADATA}"
BASE=0x40000000
addr_offset() {
	printf '0x%x' "$(( $1 - BASE ))"
}

mkbootimg \
	--kernel "${OUT_DIR}/arch/arm64/boot/Image.gz" \
	--ramdisk "${OUT_DIR}/initramfs.cpio.gz" \
	--dtb "${STOCK_DTB}" \
	--cmdline "${META[0]}" \
	--base "${BASE}" \
	--kernel_offset "$(addr_offset "${META[1]}")" \
	--ramdisk_offset "$(addr_offset "${META[2]}")" \
	--tags_offset "$(addr_offset "${META[3]}")" \
	--dtb_offset "$(addr_offset "${META[3]}")" \
	--os_version "${META[4]}" \
	--os_patch_level "${META[5]}" \
	--pagesize 2048 \
	--header_version 2 \
	--output "${OUTPUT_IMAGE}"

printf "Boot image: %s\n" "${OUTPUT_IMAGE}"
