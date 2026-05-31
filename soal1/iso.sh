
#!/bin/bash
# iso.sh - Buat bootable ISO dengan isolinux

set -e

OUTPUT_DIR="osobot"
ISO_DIR="iso_build"
OUTPUT_ISO="${OUTPUT_DIR}/farewell.iso"

# Pastikan tools terinstall
if ! command -v xorriso &> /dev/null; then
    echo "[!] xorriso not found. Installing..."
    sudo apt install -y xorriso isolinux
fi

# Buat struktur ISO
rm -rf "${ISO_DIR}"
mkdir -p "${ISO_DIR}/boot/isolinux"
mkdir -p "${ISO_DIR}/boot/syslinux"

# Copy kernel dan initramfs
cp "${OUTPUT_DIR}/bzImage" "${ISO_DIR}/boot/vmlinuz"
cp "${OUTPUT_DIR}/single.gz" "${ISO_DIR}/boot/initrd.single"
cp "${OUTPUT_DIR}/multi.gz" "${ISO_DIR}/boot/initrd.multi"

# Buat isolinux.cfg untuk menu boot
cat > "${ISO_DIR}/boot/isolinux/isolinux.cfg" << 'EOF'
DEFAULT menu
PROMPT 0
TIMEOUT 50

MENU TITLE Farewell Party Boot Menu

LABEL single
    MENU LABEL Boot Single-User Mode
    LINUX /boot/vmlinuz
    INITRD /boot/initrd.single
    APPEND console=tty1

LABEL multi
    MENU LABEL Boot Multi-User Mode
    LINUX /boot/vmlinuz
    INITRD /boot/initrd.multi
    APPEND console=tty1

LABEL hdt
    MENU LABEL Hardware Detection Tool
    COM32 hdt.c32

LABEL reboot
    MENU LABEL Reboot
    COM32 reboot.c32

LABEL poweroff
    MENU LABEL Power Off
    COM32 poweroff.c32

MENU SEPARATOR
MENU END
EOF

# Copy isolinux binaries
cp /usr/lib/ISOLINUX/isolinux.bin "${ISO_DIR}/boot/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/*.c32 "${ISO_DIR}/boot/isolinux/" 2>/dev/null || true

# Buat ISO dengan xorriso
xorriso -as mkisofs \
    -o "${OUTPUT_ISO}" \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    "${ISO_DIR}"

# Hapus file sisa
rm -rf "${ISO_DIR}"

echo "[*] Bootable ISO created at ${OUTPUT_ISO}"
