#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out-linux"
TOOLCHAIN_DIR="${ROOT_DIR}/toolchains/zyc-clang"

export ARCH=arm64
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export LD=ld.lld
export NM=llvm-nm
export AR=llvm-ar
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip
export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${TOOLCHAIN_DIR}/lib:${LD_LIBRARY_PATH:-}"

cd "${ROOT_DIR}"
clang --version

make O="${OUT_DIR}" ARCH="${ARCH}" \
	CC="${CC}" CLANG_TRIPLE="${CLANG_TRIPLE}" \
	CROSS_COMPILE="${CROSS_COMPILE}" LD="${LD}" \
	NM="${NM}" AR="${AR}" OBJCOPY="${OBJCOPY}" \
	OBJDUMP="${OBJDUMP}" STRIP="${STRIP}" \
	blossom_linux_defconfig

KCFLAGS="${KCFLAGS:--Wno-error=implicit-function-declaration}"
JOBS="${JOBS:-$(nproc)}"
make -j"${JOBS}" O="${OUT_DIR}" ARCH="${ARCH}" \
	KCFLAGS="${KCFLAGS}" \
	CC="${CC}" CLANG_TRIPLE="${CLANG_TRIPLE}" \
	CROSS_COMPILE="${CROSS_COMPILE}" LD="${LD}" \
	NM="${NM}" AR="${AR}" OBJCOPY="${OBJCOPY}" \
	OBJDUMP="${OBJDUMP}" STRIP="${STRIP}" \
	Image.gz dtbs

printf "Kernel image: %s/arch/arm64/boot/Image.gz\n" "${OUT_DIR}"
printf "Device trees: %s/arch/arm64/boot/dts/mediatek/\n" "${OUT_DIR}"
