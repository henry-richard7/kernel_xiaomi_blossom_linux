#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CLEAN_ALL=false
if [[ "${1:-}" == "--all" || "${1:-}" == "-a" ]]; then
    CLEAN_ALL=true
fi

echo "[+] Cleaning build outputs..."

if [ -d "out" ]; then
    if [ "$CLEAN_ALL" = true ]; then
        echo "[-] Removing entire out/ directory (including flashable zips)..."
        rm -rf out
    else
        echo "[-] Cleaning intermediate build objects in out/ (preserving out/flashable-kernel/)..."
        find out -mindepth 1 -maxdepth 1 ! -name 'flashable-kernel' -exec rm -rf {} +
    fi
fi

# Clean stray in-tree configs/artifacts if any exist
rm -f .config .config.old
if [ -f "include/config/auto.conf" ]; then
    echo "[-] Cleaning in-tree build artifacts (make mrproper)..."
    make mrproper >/dev/null 2>&1 || true
fi

echo "[+] Cleanup complete."
