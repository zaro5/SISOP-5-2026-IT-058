#!/bin/bash
set -e

KERNEL_VERSION="6.1.1"
KERNEL_DIR="linux-${KERNEL_VERSION}"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
OUTPUT="osboot/bzImage"

echo "[*] Downloading Linux kernel ${KERNEL_VERSION}..."
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
  wget "$KERNEL_URL"
fi

echo "[*] Extracting..."
if [ ! -d "$KERNEL_DIR" ]; then
  tar -xf "linux-${KERNEL_VERSION}.tar.xz"
fi

echo "[*] Configuring kernel..."
cd "$KERNEL_DIR"

if [ -f "../.config" ]; then
  cp "../.config" .config
  make olddefconfig
else
  make defconfig
fi

echo "[*] Compiling kernel (this may take a while)..."
make -j$(nproc) KCFLAGS="-Wno-error" bzImage

echo "[*] Copying bzImage to osboot/..."
mkdir -p ../osboot
cp arch/x86/boot/bzImage "../${OUTPUT}"

echo "[+] Done! Kernel image at: ${OUTPUT}"