# Native Linux Build Tools for Xiaomi Redmi 9A (blossom / dandelion)

Build scripts and helpers for compiling Linux 4.19 and packaging a bootable `boot-linux.img` for Redmi 9A (`dandelion` / `blossom`, MT6765 / Helio G25).

---

## Tooling Overview

* **`compile_linux.sh`**:
  Compiles the kernel image (`Image.gz`) and device tree blobs (`dtbs`) using `blossom_linux_defconfig` and ZyC Clang / LLVM toolchain into `out-linux/`.

* **`build_linux_ramdisk.sh`**:
  Extracts BusyBox from an ext4 rootfs image (e.g. Alpine Linux) and packages `out-linux/initramfs.cpio.gz` with the native Linux early init scripts.

* **`package_linux_boot.sh`**:
  Extracts the device tree and boot headers from a stock Android boot image, and packages `out-linux/boot-linux.img` containing the kernel, initramfs, stock DTB, and native Linux boot arguments (`console=ttyGS0`, `init=/init`, etc.).

* **`capture_acm.sh`**:
  Listens on host `/dev/ttyACM*` serial devices to capture kernel boot logs and provide shell access over the USB ACM gadget console.

* **`clean.sh`**:
  Cleans intermediate build files and outputs from `out-linux/` and `out/`.

---

## Build Workflow

### 1. Compile Kernel
```bash
./build-tools/compile_linux.sh
```

### 2. Build Initramfs
Ensure an ext4 rootfs image (such as `linux-rootfs.ext4`) is present:
```bash
ROOTFS_IMAGE=out-linux/linux-rootfs.ext4 ./build-tools/build_linux_ramdisk.sh
```

### 3. Package Boot Image
```bash
./build-tools/package_linux_boot.sh path/to/stock_boot.img out-linux/boot-linux.img
```

### 4. Capture USB ACM Console
While booting the phone connected to your PC via USB:
```bash
./build-tools/capture_acm.sh
```
