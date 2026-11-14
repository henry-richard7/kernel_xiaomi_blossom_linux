#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CLEAN_ALL=false
if [[ "${1:-}" == "--all" || "${1:-}" == "-a" ]]; then
    CLEAN_ALL=true
fi

echo "[+] Cleaning build outputs..."

for dir in out out-linux; do
    if [ -d "$dir" ]; then
        if [ "$CLEAN_ALL" = true ]; then
            echo "[-] Removing entire $dir/ directory..."
            rm -rf "$dir"
        else
            echo "[-] Cleaning intermediate build objects in $dir/ (preserving boot images)..."
            find "$dir" -mindepth 1 -maxdepth 1 ! -name 'boot-linux.img' ! -name 'initramfs.cpio.gz' -exec rm -rf {} +
        fi
    fi
done

# Clean stray in-tree configs/artifacts if any exist
rm -f .config .config.old
if [ -f "include/config/auto.conf" ]; then
    echo "[-] Cleaning in-tree build artifacts (make mrproper)..."
    make mrproper >/dev/null 2>&1 || true
fi

echo "[+] Cleanup complete."
