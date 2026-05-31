#!/bin/bash
# kernel.sh - Download dan compile kernel Linux 6.1.1

set -e  # stop on error

KERNEL_VERSION="6.1.1"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}"
KERNEL_DIR="linux-${KERNEL_VERSION}"
OUTPUT_DIR="osobot"

# Buat direktori output
mkdir -p "${OUTPUT_DIR}"

# Download kernel jika belum ada
if [ ! -f "${KERNEL_TAR}" ]; then
    echo "[*] Downloading kernel ${KERNEL_VERSION}..."
    wget "${KERNEL_URL}"
fi

# Extract kernel
if [ ! -d "${KERNEL_DIR}" ]; then
    echo "[*] Extracting kernel..."
    tar -xf "${KERNEL_TAR}"
fi

# Masuk ke direktori kernel
cd "${KERNEL_DIR}"

# Bersihkan kompilasi sebelumnya
make mrproper

# Copy .config jika ada, atau gunakan default
if [ -f "../.config" ]; then
    cp ../.config .config
else
    # Gunakan konfigurasi minimal, lalu menuconfig opsional
    make tinyconfig
fi

# Kompilasi kernel
echo "[*] Compiling kernel (this may take a while)..."
make -j$(nproc) CC="gcc -std=gnu89"

# Copy bzImage ke output
cp arch/x86/boot/bzImage "../${OUTPUT_DIR}/"

echo "[*] Kernel built successfully at ${OUTPUT_DIR}/bzImage"

# Cleanup (opsional, sesuai soal: hapus file sisa)
cd ..
rm -rf "${KERNEL_DIR}" "${KERNEL_TAR}"
