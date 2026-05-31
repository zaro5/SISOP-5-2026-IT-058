#!/bin/bash
# single.sh - Buat single-user filesystem dengan BusyBox

set -e

FS_DIR="rootfs_single"
OUTPUT_DIR="osobot"
OUTPUT_FILE="${OUTPUT_DIR}/single.gz"

# Bersihkan direktori sebelumnya
rm -rf "${FS_DIR}"
mkdir -p "${FS_DIR}"

# Buat struktur direktori
mkdir -p "${FS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}

# Copy busybox
cp /usr/bin/busybox "${FS_DIR}/bin/"

# Install busybox (buat symlinks)
cd "${FS_DIR}/bin"
./busybox --install .
cd ../..

# Buat file init
cat > "${FS_DIR}/init" << 'EOF'
#!/bin/sh
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys
/bin/mount -t devtmpfs none /dev

exec /bin/sh
EOF

chmod +x "${FS_DIR}/init"

# Buat device nodes minimal
cd "${FS_DIR}/dev"
mknod -m 666 console c 5 1 2>/dev/null || true
mknod -m 666 null c 1 3 2>/dev/null || true
mknod -m 666 tty1 c 4 1 2>/dev/null || true
cd ../..

# Buat initramfs
cd "${FS_DIR}"
find . | cpio -oHnewc | gzip > "../${OUTPUT_FILE}"
cd ..

# Hapus file sisa
rm -rf "${FS_DIR}"

echo "[*] Single-user filesystem created at ${OUTPUT_FILE}"
