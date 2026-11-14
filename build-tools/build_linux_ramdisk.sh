#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out-linux"
INITRAMFS_DIR="${ROOT_DIR}/linux/initramfs"
ROOTFS_IMAGE="${ROOTFS_IMAGE:-${OUT_DIR}/linux-rootfs.ext4}"
OUTPUT="${OUT_DIR}/initramfs.cpio.gz"

if [ ! -f "${ROOTFS_IMAGE}" ]; then
	echo "Alpine rootfs image not found: ${ROOTFS_IMAGE}" >&2
	echo "Set ROOTFS_IMAGE to an ext4 rootfs image containing /bin/busybox." >&2
	exit 1
fi

if ! command -v debugfs >/dev/null 2>&1; then
	echo "debugfs is required to extract BusyBox from the ext4 rootfs image." >&2
	exit 1
fi

mkdir -p "${OUT_DIR}"
STAGE_DIR="$(mktemp -d "${OUT_DIR}/initramfs.XXXXXX")"
trap 'rm -rf "${STAGE_DIR}"' EXIT

mkdir -p "${STAGE_DIR}/bin" "${STAGE_DIR}/sbin" \
	"${STAGE_DIR}/lib" \
	"${STAGE_DIR}/dev" "${STAGE_DIR}/proc" "${STAGE_DIR}/sys" \
	"${STAGE_DIR}/mnt/sd" "${STAGE_DIR}/newroot"

debugfs -R "dump /bin/busybox ${STAGE_DIR}/bin/busybox" "${ROOTFS_IMAGE}" >/dev/null 2>&1
debugfs -R "dump /lib/ld-musl-aarch64.so.1 ${STAGE_DIR}/lib/ld-musl-aarch64.so.1" "${ROOTFS_IMAGE}" >/dev/null 2>&1
chmod 0755 "${STAGE_DIR}/bin/busybox" "${STAGE_DIR}/lib/ld-musl-aarch64.so.1"
ln -s ld-musl-aarch64.so.1 "${STAGE_DIR}/lib/libc.musl-aarch64.so.1"
install -m 0755 "${INITRAMFS_DIR}/init" "${STAGE_DIR}/init"

if [ -d "${ROOT_DIR}/firmware" ]; then
	mkdir -p "${STAGE_DIR}/lib/firmware"
	cp -a "${ROOT_DIR}/firmware"/* "${STAGE_DIR}/lib/firmware/" 2>/dev/null || true
fi

for applet in sh mount losetup switch_root sleep mkdir dmesg cat; do
	ln -s busybox "${STAGE_DIR}/bin/${applet}"
done

(
	cd "${STAGE_DIR}"
	find . -print0 | sort -z | cpio --null -o -H newc --owner=0:0
) | gzip -n -9 > "${OUTPUT}"

echo "Initramfs created: ${OUTPUT}"
echo "Rootfs image expected on the microSD: /linux-rootfs.ext4"
