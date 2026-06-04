#!/bin/bash
set -e

ISO_DIR="iso_build"
OUTPUT="osboot/farewell.iso"
BZIMAGE="osboot/bzImage"
SINGLE="osboot/single.gz"
MULTI="osboot/multi.gz"

# Check files exist
for f in "$BZIMAGE" "$SINGLE" "$MULTI"; do
  [ -f "$f" ] || { echo "[!] Missing: $f"; exit 1; }
done

echo "[*] Building ISO structure..."
rm -rf "$ISO_DIR"
mkdir -p "${ISO_DIR}/boot/grub"
mkdir -p "${ISO_DIR}/boot/fs"

cp "$BZIMAGE" "${ISO_DIR}/boot/"
cp "$SINGLE"  "${ISO_DIR}/boot/fs/"
cp "$MULTI"   "${ISO_DIR}/boot/fs/"

# GRUB config — boot menu for single and multi
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Farewell Party - Single User" {
  linux  /boot/bzImage quiet
  initrd /boot/fs/single.gz
}

menuentry "Farewell Party - Multi User" {
  linux  /boot/bzImage quiet
  initrd /boot/fs/multi.gz
}
EOF

echo "[*] Creating ISO: ${OUTPUT}..."
grub-mkrescue -o "$OUTPUT" "$ISO_DIR" 2>/dev/null

rm -rf "$ISO_DIR"
echo "[+] Done! ISO at: ${OUTPUT}"