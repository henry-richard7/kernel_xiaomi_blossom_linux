#!/bin/bash
set -euo pipefail

# Build script for with KernelSU
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

export KERNEL_DEFCONFIG="blossom_defconfig"
export KERNEL_ARCH="arm64"
export ARCH="${KERNEL_ARCH}"

# Toolchain setup
TOOLCHAIN_DIR="${ROOT_DIR}/toolchains/zyc-clang"
export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${TOOLCHAIN_DIR}/lib:${LD_LIBRARY_PATH:-}"

clang --version

# Ensure lowmemorykiller is set up
if [ -f drivers/android/dummy_lmk.c ]; then
    mv drivers/android/dummy_lmk.c drivers/android/lowmemorykiller.c
fi

# Ensure KernelSU submodule and symlink are present
if [ ! -f "KernelSU/kernel/Kconfig" ]; then
    git submodule update --init --recursive KernelSU
fi

if [ ! -L "drivers/kernelsu" ]; then
    ln -sf ../KernelSU/kernel drivers/kernelsu
fi

# Toolchain flags
export CC="clang"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export CROSS_COMPILE="aarch64-linux-gnu-"
export LD="ld.lld"
export NM="llvm-nm"
export AR="llvm-ar"
export OBJCOPY="llvm-objcopy"
export OBJDUMP="llvm-objdump"
export STRIP="llvm-strip"

# Generate defconfig in out/
make O=out \
    ARCH=${ARCH} \
    CC=${CC} \
    CLANG_TRIPLE=${CLANG_TRIPLE} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    LD=${LD} \
    NM=${NM} \
    AR=${AR} \
    OBJCOPY=${OBJCOPY} \
    OBJDUMP=${OBJDUMP} \
    STRIP=${STRIP} \
    ${KERNEL_DEFCONFIG}

# Apply kernel version from VERSION file if present
KERNEL_VERSION="1.4"
if [ -f "${ROOT_DIR}/VERSION" ]; then
    KERNEL_VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
    "${ROOT_DIR}/scripts/config" --file "${ROOT_DIR}/out/.config" --set-str LOCALVERSION "-HenryKernel-v${KERNEL_VERSION}"
fi

# Compile kernel
KCFLAGS="-Wno-error=implicit-function-declaration"

make -j$(nproc) \
    KCFLAGS="${KCFLAGS}" \
    O=out \
    ARCH=${ARCH} \
    CC=${CC} \
    CLANG_TRIPLE=${CLANG_TRIPLE} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    LD=${LD} \
    NM=${NM} \
    AR=${AR} \
    OBJCOPY=${OBJCOPY} \
    OBJDUMP=${OBJDUMP} \
    STRIP=${STRIP}

# Package AnyKernel3 zip
echo "[+] Packaging flashable AnyKernel3 zip..."
python3 "${ROOT_DIR}/build-tools/package_anykernel.py" "${ROOT_DIR}/out/flashable-kernel/Kernel-dandelion-KSU-v${KERNEL_VERSION}.zip"
cp -f "${ROOT_DIR}/out/flashable-kernel/Kernel-dandelion-KSU-v${KERNEL_VERSION}.zip" "${ROOT_DIR}/out/flashable-kernel/Kernel-dandelion-KSU.zip"
