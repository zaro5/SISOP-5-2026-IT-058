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

Selanjutnya buat file `single.sh` dan jalankan untuk menghasilkan `single.gz` yang terlokasi di direktori `osboot/`.

```c
#!/bin/bash
set -e

BUSYBOX_VERSION="1.37.0"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
ROOTFS_DIR="rootfs_single"
OUTPUT="osboot/single.gz"

# ── Download & build BusyBox ──────────────────────────────────────────
echo "[*] Downloading BusyBox..."
if [ ! -f "busybox-${BUSYBOX_VERSION}.tar.bz2" ]; then
  wget "$BUSYBOX_URL"
fi

if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
  tar -xf "busybox-${BUSYBOX_VERSION}.tar.bz2"
fi

cd "busybox-${BUSYBOX_VERSION}"
make defconfig
# Enable static build
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make -j$(nproc)
make CONFIG_PREFIX="../${ROOTFS_DIR}" install
cd ..

# ── Build rootfs ──────────────────────────────────────────────────────
echo "[*] Building single-user rootfs..."
rm -rf "$ROOTFS_DIR"
mkdir -p "${ROOTFS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}

# Copy BusyBox (already installed above, redo cleanly)
cd "busybox-${BUSYBOX_VERSION}"
make CONFIG_PREFIX="../${ROOTFS_DIR}" install
cd ..

# Dev nodes
sudo mknod "${ROOTFS_DIR}/dev/console" c 5 1
sudo mknod "${ROOTFS_DIR}/dev/null"    c 1 3
sudo mknod "${ROOTFS_DIR}/dev/tty"     c 5 0
sudo mknod "${ROOTFS_DIR}/dev/sda"     b 8 0

# /etc/passwd  (root only)
cat > "${ROOTFS_DIR}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

# /etc/shadow  (root:root123)
HASH=$(openssl passwd -1 "root123")
cat > "${ROOTFS_DIR}/etc/shadow" << EOF
root:${HASH}:0:0:99999:7:::
EOF

# /etc/group
cat > "${ROOTFS_DIR}/etc/group" << 'EOF'
root:x:0:root
EOF

# Banner + login via /etc/profile
cat > "${ROOTFS_DIR}/etc/profile" << 'EOF'
figlet "Farewell Party" 2>/dev/null || cat << 'BANNER'
  _____                          _ _   ____            _
 |  ___|_ _ _ __ _____      _____| | | |  _ \ __ _ _ __| |_ _   _
 | |_ / _` | '__/ _ \ \ /\ / / _ \ | | | |_) / _` | '__| __| | | |
 |  _| (_| | | |  __/\ V  V /  __/ | | |  __/ (_| | |  | |_| |_| |
 |_|  \__,_|_|  \___| \_/\_/ \___|_| |_|_|   \__,_|_|   \__|\__, |
                                                               |___/
BANNER
echo "Welcome, $(whoami)."
EOF

# Init script
cat > "${ROOTFS_DIR}/init" << 'EOF'
#!/bin/sh
mount -t proc  none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

echo ":: Single-user mode ::"
exec /bin/login
EOF
chmod +x "${ROOTFS_DIR}/init"

# Set permissions — root owns everything, root can access all
sudo chown -R root:root "${ROOTFS_DIR}"
sudo chmod 700 "${ROOTFS_DIR}/root"
sudo chmod 1777 "${ROOTFS_DIR}/tmp"

# Pack initramfs
echo "[*] Packing initramfs -> ${OUTPUT}..."
mkdir -p osboot
cd "$ROOTFS_DIR"
find . | cpio -H newc -o | gzip > "../${OUTPUT}"
cd ..

# Cleanup leftover build files
rm -rf "$ROOTFS_DIR"

echo "[+] Done! single filesystem at: ${OUTPUT}"
```
