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