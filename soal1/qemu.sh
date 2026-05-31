#!/bin/bash
# qemu.sh - Menjalankan QEMU dengan berbagai mode

set -e

KERNEL="osobot/bzImage"
SINGLE_INITRD="osobot/single.gz"
MULTI_INITRD="osobot/multi.gz"
ISO="osobot/farewell.iso"

# Fungsi untuk boot single
boot_single() {
    echo "[*] Booting single-user mode..."
    qemu-system-x86_64 \
        -kernel "${KERNEL}" \
        -initrd "${SINGLE_INITRD}" \
        -append "console=tty1" \
        -m 256 \
        -smp 2 \
        -display curses
}

# Fungsi untuk boot multi
boot_multi() {
    echo "[*] Booting multi-user mode..."
    qemu-system-x86_64 \
        -kernel "${KERNEL}" \
        -initrd "${MULTI_INITRD}" \
        -append "console=tty1" \
        -m 512 \
        -smp 2 \
        -display curses
}

# Fungsi untuk boot dari ISO dengan menu
boot_iso() {
    echo "[*] Booting from ISO with menu selection..."
    qemu-system-x86_64 \
        -cdrom "${ISO}" \
        -m 512 \
        -smp 2 \
        -display curses
}

# Parse argument
case "$1" in
    --single)
        boot_single
        ;;
    --multi)
        boot_multi
        ;;
    --all)
        boot_iso
        ;;
    *)
        echo "Usage: $0 --single | --multi | --all"
        echo "  --single   : Boot single-user filesystem directly"
        echo "  --multi    : Boot multi-user filesystem directly"
        echo "  --all      : Boot from ISO with menu selection"
        exit 1
        ;;
esac