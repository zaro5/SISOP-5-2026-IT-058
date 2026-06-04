# SISOP-5-2026-IT-058

## Member
| No | Nama Lengkap | NRP |
|---|---|---|
| 01 | [Nama Anda] | [NRP Anda] |

## Reporting

### SOAL 1 - Farewell Party

#### Penjelasan

Langkah pertama adalah melakukan instalasi `Linux-6.1.1`. Jika sudah, extrack file di dalamnya dan lakukan `make tinyconfig` dan `make menuconfig`. Dalam file `.config` sesuaikan dengan ketentuan yang diminta pada Modul GitHub yang diberikan, kemudian simpan. 

Setelahnya, buat file kernel.sh dan jalankan untuk konfigurasi kernel. 

```c
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
```
