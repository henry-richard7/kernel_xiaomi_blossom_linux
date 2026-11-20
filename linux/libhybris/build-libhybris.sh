#!/bin/sh
# Build and install patched libhybris on Alpine Linux (aarch64, musl libc)
# Designed for MediaTek Helio G25 (MT6765) with PowerVR Rogue GE8320 (Android 10/11 bionic blobs)
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/patches"

# 1. Install prerequisites
apk add --no-cache build-base autoconf automake libtool pkgconf git linux-headers

# 2. Clone libhybris if not already cloned
if [ ! -d "libhybris" ]; then
    git clone https://github.com/libhybris/libhybris.git
fi

cd libhybris

# 3. Apply musl compatibility & gralloc1 fbdev patches
git checkout master
git apply "${PATCH_DIR}/0001-libhybris-musl-android10-blossom.patch"

# Copy extra header files
cp "${PATCH_DIR}/musl_hooks_compat.h" hybris/common/
mkdir -p hybris/common/q/bionic/libc/include/sys
cp "${PATCH_DIR}/cdefs.h" hybris/common/q/bionic/libc/include/sys/

# 4. Generate build configuration
./autogen.sh

# 5. Configure with Android 10+ bionic support and fbdev platform
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --enable-arch=arm64 \
    --enable-android-version=10.0.0 \
    --enable-wayland=no \
    --enable-fbdev=yes \
    --enable-mali-quirks=no \
    --enable-adreno-quirks=no \
    --with-android-headers=/root/android-headers \
    CFLAGS="-O2 -fPIC -D__MUSL__ -D_GNU_SOURCE -I/root/android-headers" \
    CXXFLAGS="-O2 -fPIC -D__MUSL__ -D_GNU_SOURCE -I/root/android-headers"

# 6. Compile and install
make -j"$(nproc)"
make install

echo "[✔] Patched libhybris installed successfully!"
