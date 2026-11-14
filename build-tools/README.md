# Henry Kernel for Xiaomi Redmi 9A (dandelion / blossom)

<center>
<pre> *
 * Your warranty is now void.
 *
 * I am not responsible for bricked devices, dead SD cards,
 * thermonuclear war, or you getting fired because the alarm app failed. Please
 * do some research if you have any concerns about features included in this kernel
 * before flashing it! YOU are choosing to make these modifications, and if
 * you point the finger at me for messing up your device, I will laugh at you.
 *
</pre>
Custom Linux 4.19 kernel designed specifically for Xiaomi Redmi 9A (<code>dandelion</code> / <code>blossom</code>, MediaTek MT6765) to improve multitasking, networking, performance, and memory responsiveness.
</center>

---

## General Features

1. **Full Source Disclosure & Transparency:** All modifications, driver sources, and build scripts are fully disclosed in this repository in compliance with the GNU General Public License (GPL). Build and packaging scripts reside cleanly in the [`build-tools/`](.) directory. Recent driver integration, performance tuning, and build tooling utilized AI pair-programming assistance under human verification (see [AI Disclosure](../AI_DISCLOSURE.md)).
2. **External Wi-Fi Adapter Support:**
   - **Realtek RTL8812BU / RTL8822BU:** Integrated into `drivers/net/wireless/realtek/rtl88x2bu/` with plug-and-play support for the **TP-Link Archer T4U Plus v1** (`2357:0115`).
   - **Atheros AR9271 (`ath9k_htc`):** Built-in driver with embedded upstream firmware (`firmware/ath9k_htc/htc_9271-1.4.0.fw`) for the **TP-Link TL-WN722N v1** (`0cf3:9271`).
3. **Official KernelSU via Git Submodule:**
   - Official backport of KernelSU integrated cleanly as a tracked Git submodule at [`KernelSU/`](https://github.com/backslashxx/KernelSU) with symlink integration into `drivers/kernelsu`.
   - No destructive `curl | bash` script downloads during compilation.
4. **Overclocking & Interconnect Fix:**
   - Tuned CPU (+200 MHz BIG, +200 MHz LITTLE) and GPU (+30 MHz) frequencies with boosted cellular MD1 TX power (5500 mW).
   - Fixed Cache Coherent Interconnect (CCI) OPP table scaling (`opp08`–`opp11`), eliminating the 10x frequency drop under moderate load and sustaining high-speed 763–878 MHz memory coherence bus speeds.
5. **Memory Management & Storage Responsiveness:**
   - Multi-generational LRU (MGLRU), parallelized kcompressd, and kshrinkd.
   - Faster ZRAM throughput via updated ARMv8 assembly-accelerated LZ4 compression.
   - **BFQ I/O Scheduler & Multi-Queue Device Mapper (`DM_MQ`):** Prioritizes interactive UI foreground tasks over background storage writes on slow eMMC 5.1 storage.
   - Android Low Memory Killer disabled via in-kernel dummy driver to prevent aggressive background app kills (Linux standard OOM killer remains active).
6. **Timer & Energy-Aware Scheduling:**
   - **Tickless Idle (`NO_HZ_IDLE`):** Stops ticks on idle cores, saving battery and allowing deep C-states (SPM/MCDI) while eliminating per-syscall context tracking and virtual CPU accounting overhead.
   - **300 Hz Timer Frequency:** Reduces CPU wakeups by 70% compared to 1000 Hz while cleanly synchronizing with 60 Hz display refresh cycles (5 ticks per frame).
   - **Energy-Aware Scheduling (EAS):** Default `schedutil` governor dynamically scales frequencies from early boot alongside PELT 8ms.
7. **Hardware Cryptography & Networking:**
   - **In-Silicon ARMv8 Crypto Extensions:** Hardware acceleration enabled for GHASH (AES-GCM for Android File-Based Encryption), AES-CCM (WPA2/WPA3 Wi-Fi), PMULL CRC, SHA-1, SHA-512, and bit-sliced NEON AES.
   - **BBR & Fair Queueing (`fq`):** Default `fq` packet scheduler enabled to support BBR TCP congestion control pacing.
   - WireGuard integrated in-tree, SRANDOM driver for high-throughput `/dev/urandom`.
8. **Compiler Optimizations & Clean Tooling:**
   - Compiled with ZyC Clang 21, Full Link-Time Optimization (Full LTO), Polly loop vectorizer, `-O3`, and Cortex-A53 target tuning.
   - Tuned inlining threshold (500) prevents instruction cache bloating and thrashing on the 32 KB L1-icache of Cortex-A53 cores.
   - OpenSSL 3/4 engine compatibility in kernel certificate and signing host tools (`extract-cert.c` and `sign-file.c`).

---

## Device-Specific Notes

- **Target Device:** Xiaomi Redmi 9A / 9i / 9A Sport (`dandelion` / `blossom` / `angelica` / `cattail` — MT6765).
- **Base Kernel:** Upstreamed Linux `4.19.325`.
- **Supported ROMs:** Android 11+ 64-bit R-vendor AOSP ROMs (CrDroid 13 / Android 17 and MIUI are not supported).

---

## Building the Kernel

### 1. Prerequisites & Toolchain
The build scripts use ZyC Clang 21. Place the toolchain at `toolchains/zyc-clang`:
```bash
git clone https://gitlab.com/clangsantoni/zyc_clang --depth=1 --branch 21 toolchains/zyc-clang
```

Ensure the KernelSU submodule is initialized:
```bash
git submodule update --init --recursive
```

### 2. Compile Kernel with KernelSU
```bash
bash build-tools/compile_ksu.sh
```
This builds the kernel image and automatically packages a flashable AnyKernel3 zip into:
```
out/flashable-kernel/Kernel-dandelion-KSU-v1.4.zip
```

### 3. Compile Vanilla Kernel (Without KernelSU)
```bash
bash build-tools/compile_noksu.sh
```
Outputs flashable zip to:
```
out/flashable-kernel/Kernel-dandelion-VANILLA-v1.4.zip
```

### 4. Versioning
Kernel releases are tracked in the top-level [`VERSION`](../VERSION) file (currently `1.4`).
Whenever a major update occurs, incrementing `VERSION` automatically synchronizes:
- The Linux kernel release string (`4.19.325-HenryKernel-v<VERSION>`)
- The AnyKernel3 installer display banner (`Henry Kernel v<VERSION>`)
- The output flashable zip artifact filename

### 5. Cleaning the Build Tree
- **Clean intermediate build files (keeps generated flashable zips):**
  ```bash
  ./clean.sh
  ```
- **Wipe everything (including generated zips and configs):**
  ```bash
  ./clean.sh --all
  ```

---

## AnyKernel3 Recovery Installer

The repository includes a generic AnyKernel3 template tailored for Redmi 9A (`dandelion`):
- Template: [`anykernel_template/`](../anykernel_template/)
- Packager: [`package_anykernel.py`](package_anykernel.py)
- Automatically embeds `Image` and `Image.gz`, preserves required executable permissions (`0755`) for update binaries, and handles slotless block flashing.

---

## AI Disclosure
In the interest of full transparency and open-source best practices, see [AI_DISCLOSURE.md](../AI_DISCLOSURE.md) for details on the AI-assisted pair-programming contributions and human verification process.
