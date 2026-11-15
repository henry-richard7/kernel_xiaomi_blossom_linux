# Native Alpine Linux on Xiaomi Redmi 9A (blossom / dandelion)

Native GNU/Linux port for the Xiaomi Redmi 9A (MediaTek Helio G25 / MT6765 / MT6762G), booting directly into Alpine Linux from an external microSD card without modifying or endangering internal Android eMMC partitions.

---

## Hardware Support & Status

| Subsystem | Driver / Mechanism | Status | Notes |
| :--- | :--- | :--- | :--- |
| **CPU / SoC** | MediaTek MT6765 (Helio G25) 8x Cortex-A53 | **Working** | Full multicore support |
| **Display** | SimpleFB / Framebuffer (`/dev/fb0`) | **Working** | 720 × 1600 resolution |
| **Touchscreen** | Novatek TS (`novatek_ts_djn_fw.bin`) | **Working** | Firmware embedded into kernel & ramdisk |
| **Internal Wi-Fi** | MediaTek `wmt-wifi` / `wmt-pyloader` (`wlan0`) | **Working** | Loads MTK combo firmware & connects on boot |
| **USB Tethering** | Linux ConfigFS RNDIS (`usb0`) | **Working** | Managed via `/usr/local/bin/usb-tether` |
| **USB Serial Console** | Linux ConfigFS ACM (`ttyGS0`) | **Working** | Root shell on `/dev/ttyACM*` on PC |
| **Direct Screen Shell** | OpenRC autologin on `/dev/tty1` | **Working** | Root prompt directly on phone display |
| **Battery / PMIC** | Stock MTK Power Supply & Charger | **Working** | Battery percentage & charging active |
| **Backlight Control** | MediaTek LCD Backlight (`lcd-backlight`) | **Working** | Controlled via `brightnessctl` |
| **External USB Wi-Fi** | `ath9k_htc` & `rtl8822bu` | **Working** | Built-in kernel drivers |
| **External USB BT** | `btusb` (Realtek RTL8761BU / TP-Link UB500) | **Working** | Built-in kernel drivers |
| **Storage** | MicroSD (`/dev/mmcblk1p1` -> `linux-rootfs.ext4` loop) | **Working** | Safe, isolated non-destructive boot |

---

## Quick Start / Build Guide

The project provides a top-level unified build script: [`./build.sh`](file:///media/primaryHdd/Coding/Android/kernel_xiaomi_blossom_linux/build.sh).

### 1. Build the Boot Image
```bash
./build.sh boot
```
* Automatically compiles the Linux kernel (`out-linux/arch/arm64/boot/Image.gz`) if not already built.
* Generates the initramfs (`out-linux/initramfs.cpio.gz`).
* Extracts the stock DTB and metadata from your stock boot backup.
* Repacks and outputs [`out-linux/boot-linux.img`](file:///media/primaryHdd/Coding/Android/kernel_xiaomi_blossom_linux/out-linux/boot-linux.img).

### 2. Available Build Subcommands
* **`./build.sh kernel`**: Compiles kernel image and device trees using `blossom_linux_defconfig`.
* **`./build.sh ramdisk`**: Rebuilds the native initramfs.
* **`./build.sh rootfs`**: Generates the 5 GiB Alpine Linux ext4 rootfs image.
* **`./build.sh all`**: Builds kernel, ramdisk, boot image, and rootfs in one go.
* **`./build.sh flash`**: Flashes `out-linux/boot-linux.img` via fastboot.
* **`./build.sh console`**: Connects to the phone's live USB ACM serial console.
* **`./build.sh clean`**: Cleans intermediate build objects.

---

## MicroSD Card Setup & Booting

1. Format your microSD card's first partition (`/dev/mmcblk1p1`) as **FAT32** or **ext4**.
2. Copy the generated `linux-rootfs.ext4` to the root of the microSD card:
   ```bash
   cp /media/primaryHdd/Coding/Android/alpine-rootfs/linux-rootfs.ext4 /path/to/microsd/
   ```
3. Put the phone into Fastboot mode (**Hold Volume Down + Power**).
4. Flash the boot image:
   ```bash
   fastboot flash boot out-linux/boot-linux.img
   fastboot reboot
   ```

---

## Key On-Device Commands (Inside Alpine Linux)

### Wi-Fi (`wlan0`)
Wi-Fi starts and connects automatically on boot. If you need to reconfigure:
* Scan networks:
  ```sh
  iw dev wlan0 scan
  ```
* Add credentials:
  ```sh
  wpa_passphrase "SSID" "PASSWORD" >> /etc/wpa_supplicant/wpa_supplicant.conf
  rc-service wpa_supplicant restart
  ```

### USB Tethering (`usb-tether`)
Share your PC's internet with the phone over USB (or vice versa):
```sh
usb-tether on
udhcpc -i usb0
```
To disable:
```sh
usb-tether off
```

### Screen Brightness
Adjust backlight brightness:
```sh
brightnessctl set 50%
# or directly:
echo 500 > /sys/class/leds/lcd-backlight/brightness
```

### Graphical Desktop
To start the Xorg Openbox desktop with on-screen keyboard:
```sh
start-desktop
# or simply:
startx
```

### Clean Power Off / Battery Calibration
* Always shut down cleanly from the shell:
  ```sh
  poweroff
  ```
* **Battery Tip:** If the battery reading ever desyncs after an unexpected crash, boot into Recovery mode, select **"Power off"** from the recovery menu, and then power the phone on normally. This resets the PMIC fuel gauge cleanly.
