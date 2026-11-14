#!/usr/bin/env python3
import os
import sys
import zipfile
import re

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE_DIR = os.path.join(ROOT_DIR, "anykernel_template")
OUT_BOOT_DIR = os.path.join(ROOT_DIR, "out", "arch", "arm64", "boot")
DEFAULT_OUT_DIR = os.path.join(ROOT_DIR, "out", "flashable-kernel")

def get_kernel_version():
    version_file = os.path.join(ROOT_DIR, "VERSION")
    if os.path.isfile(version_file):
        with open(version_file, "r") as f:
            v = f.read().strip()
            if v:
                return v
    return "1.4"

def main():
    version_str = get_kernel_version()

    if len(sys.argv) > 1:
        target = sys.argv[1]
        if not os.path.isabs(target) and not os.path.dirname(target):
            output_zip = os.path.join(DEFAULT_OUT_DIR, target)
        else:
            output_zip = os.path.abspath(target)
    else:
        output_zip = os.path.join(DEFAULT_OUT_DIR, f"Kernel-dandelion-KSU-v{version_str}.zip")

    out_dir = os.path.dirname(output_zip)
    os.makedirs(out_dir, exist_ok=True)

    if not os.path.isdir(TEMPLATE_DIR):
        print(f"[-] Error: AnyKernel template directory not found at {TEMPLATE_DIR}", file=sys.stderr)
        sys.exit(1)

    image_path = os.path.join(OUT_BOOT_DIR, "Image")
    image_gz_path = os.path.join(OUT_BOOT_DIR, "Image.gz")

    if not os.path.exists(image_path) and not os.path.exists(image_gz_path):
        print(f"[-] Error: No kernel image found in {OUT_BOOT_DIR}. Please compile the kernel first.", file=sys.stderr)
        sys.exit(1)

    print(f"[+] Creating AnyKernel3 zip: {output_zip} (v{version_str})")
    file_count = 0

    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        # Add kernel images
        for img in [image_path, image_gz_path]:
            if os.path.exists(img):
                arcname = os.path.basename(img)
                size_mb = os.path.getsize(img) / (1024 * 1024)
                print(f"  -> Adding {arcname} ({size_mb:.1f} MB)")
                zinfo = zipfile.ZipInfo.from_file(img, arcname=arcname)
                zinfo.external_attr = 0o100755 << 16
                with open(img, "rb") as f:
                    zf.writestr(zinfo, f.read())
                file_count += 1

        # Add AnyKernel template files
        for root, dirs, files in os.walk(TEMPLATE_DIR):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, TEMPLATE_DIR)
                st = os.stat(full_path)
                mode = st.st_mode
                zinfo = zipfile.ZipInfo.from_file(full_path, arcname=rel_path)
                zinfo.external_attr = (mode & 0xFFFF) << 16

                with open(full_path, "rb") as f:
                    content = f.read()

                # Dynamically update version banner in anykernel.sh
                if rel_path == "anykernel.sh":
                    text = content.decode("utf-8")
                    text = re.sub(
                        r"kernel\.string=.*",
                        f"kernel.string=Henry Kernel v{version_str} for Redmi 9A (dandelion)",
                        text,
                    )
                    content = text.encode("utf-8")

                zf.writestr(zinfo, content)
                file_count += 1

    zip_size_mb = os.path.getsize(output_zip) / (1024 * 1024)
    print(f"[+] Done! Package created successfully: {output_zip} ({zip_size_mb:.2f} MB, {file_count} files)")

if __name__ == "__main__":
    main()
