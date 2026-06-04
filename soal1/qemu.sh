#!/bin/bash
set -e

BZIMAGE="osboot/bzImage"
SINGLE="osboot/single.gz"
MULTI="osboot/multi.gz"
ISO="osboot/farewell.iso"

QEMU="qemu-system-x86_64"
QEMU_ARGS="-m 512M -nographic -serial mon:stdio \
  -netdev user,id=net0 -device e1000,netdev=net0"

usage() {
  echo "Usage: $0 [--single | --multi | --all]"
  exit 1
}

case "$1" in
  --single)
    echo "[*] Booting single-user filesystem..."
    $QEMU $QEMU_ARGS \
      -kernel "$BZIMAGE" \
      -initrd "$SINGLE" \
      -append "console=ttyS0 rdinit=/init"
    ;;

  --multi)
    echo "[*] Booting multi-user filesystem..."
    $QEMU $QEMU_ARGS \
      -kernel "$BZIMAGE" \
      -initrd "$MULTI" \
      -append "console=ttyS0 rdinit=/init"
    ;;

  --all)
    echo "[*] Booting from ISO (select single/multi from GRUB menu)..."
    $QEMU $QEMU_ARGS \
      -cdrom "$ISO" \
      -boot d
    ;;

  *)
    usage
    ;;
esac