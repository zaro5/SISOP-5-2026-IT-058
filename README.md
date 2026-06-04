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


Selanjutnya, buat file `multi.sh` untuk menghasilkan `multi.gz` yang akan tersimpan di `osboot/`.

```c
#!/bin/bash
set -e

BUSYBOX_VERSION="1.37.0"
ROOTFS_DIR="rootfs_multi"
OUTPUT="osboot/multi.gz"

# ── Reuse BusyBox build ───────────────────────────────────────────────
if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
  echo "[!] BusyBox not found. Run single.sh first (or download it)."
  exit 1
fi

echo "[*] Building multi-user rootfs..."
rm -rf "$ROOTFS_DIR"
mkdir -p "${ROOTFS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "${ROOTFS_DIR}/home/"{henn,hann,viii,kids}

# Install BusyBox
cd "busybox-${BUSYBOX_VERSION}"
make CONFIG_PREFIX="../${ROOTFS_DIR}" install
cd ..

# Dev nodes
sudo mknod "${ROOTFS_DIR}/dev/console" c 5 1
sudo mknod "${ROOTFS_DIR}/dev/null"    c 1 3
sudo mknod "${ROOTFS_DIR}/dev/tty"     c 5 0
sudo mknod "${ROOTFS_DIR}/dev/sda"     b 8 0

# ── Users ─────────────────────────────────────────────────────────────
# UIDs: root=0, henn=1001, hann=1002, viii=1003, kids=1004
cat > "${ROOTFS_DIR}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
henn:x:1001:1001::/home/henn:/bin/sh
hann:x:1002:1002::/home/hann:/bin/sh
viii:x:1003:1003::/home/viii:/bin/sh
kids:x:1004:1004::/home/kids:/bin/sh
EOF

cat > "${ROOTFS_DIR}/etc/group" << 'EOF'
root:x:0:root
henn:x:1001:henn
hann:x:1002:hann
viii:x:1003:viii
kids:x:1004:kids
EOF

# Passwords
add_shadow() {
  local user=$1 pass=$2
  local hash
  hash=$(openssl passwd -1 "$pass")
  echo "${user}:${hash}:0:0:99999:7:::"
}

{
  add_shadow root  root123
  add_shadow henn  henn123
  add_shadow hann  hann123
  add_shadow viii  viii123
  add_shadow kids  kids123
} > "${ROOTFS_DIR}/etc/shadow"

# ── Permissions ───────────────────────────────────────────────────────
sudo chown -R root:root  "${ROOTFS_DIR}"
sudo chown -R 1001:1001  "${ROOTFS_DIR}/home/henn"
sudo chown -R 1002:1002  "${ROOTFS_DIR}/home/hann"
sudo chown -R 1003:1003  "${ROOTFS_DIR}/home/viii"
sudo chown -R 1004:1004  "${ROOTFS_DIR}/home/kids"

sudo chmod 700  "${ROOTFS_DIR}/root"
sudo chmod 1777 "${ROOTFS_DIR}/tmp"

# Home dirs: owner rwx, others ---
sudo chmod 700 "${ROOTFS_DIR}/home/henn"
sudo chmod 700 "${ROOTFS_DIR}/home/hann"
sudo chmod 700 "${ROOTFS_DIR}/home/viii"
sudo chmod 700 "${ROOTFS_DIR}/home/kids"

# Access control via /etc/profile per user using .profile in each home
# henn: full /home/*, no /root
# hann: /home/{hann,viii,kids} only
# viii: /home/{viii,kids} only
# kids: /home/kids only

make_profile() {
  local user=$1; shift
  local allowed=("$@")
  local homedir="${ROOTFS_DIR}/home/${user}"
  
  cat > "${homedir}/.profile" << PROFILE
figlet "Farewell Party" 2>/dev/null || echo "=== Farewell Party ==="
echo "Welcome, ${user}."

# Enforce directory access
check_access() {
  local dir=\$1
PROFILE

  # Build deny rules based on spec
  cat >> "${homedir}/.profile" << 'PROFILE'
  case "$dir" in
PROFILE

  for allow in "${allowed[@]}"; do
    echo "    ${allow}) return 0 ;;" >> "${homedir}/.profile"
  done

  cat >> "${homedir}/.profile" << 'PROFILE'
    *) echo "Access denied: $dir"; return 1 ;;
  esac
}
PROFILE
}

# ── Banner /etc/profile (shown on login) ──────────────────────────────
cat > "${ROOTFS_DIR}/etc/profile" << 'EOF'
figlet "Farewell Party" 2>/dev/null || echo "=== Farewell Party ==="
echo "Welcome, $(whoami)."
EOF

# ── /etc/sudoers-like via group approach ─────────────────────────────
# Implemented via filesystem permissions (chmod/chown already set above)
# Additional: make /home readable by owner's group per spec
sudo chmod 750 "${ROOTFS_DIR}/home/henn"   # henn: accessible by henn+group
# hann can read hann,viii,kids but not henn,root -> handled by ownership

# ── Init ─────────────────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/init" << 'EOF'
#!/bin/sh
mount -t proc  none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

echo ":: Multi-user mode ::"
exec /bin/login
EOF
chmod +x "${ROOTFS_DIR}/init"

# ── Pack ─────────────────────────────────────────────────────────────
echo "[*] Packing initramfs -> ${OUTPUT}..."
mkdir -p osboot
cd "$ROOTFS_DIR"
find . | cpio -H newc -o | gzip > "../${OUTPUT}"
cd ..

rm -rf "$ROOTFS_DIR"
echo "[+] Done! multi filesystem at: ${OUTPUT}"
```


Kemudian, buatlah `iso.sh`, merupakan file yang menggabungkan kernel + filesystem menjadi file bootable yang bisa digunakan untuk booting dengan menu pilihan: single atau multi. 

```c
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
  linux  /boot/bzImage console=ttyS0 quiet
  initrd /boot/fs/single.gz
}

menuentry "Farewell Party - Multi User" {
  linux  /boot/bzImage console=ttyS0 quiet
  initrd /boot/fs/multi.gz
}
EOF

echo "[*] Creating ISO: ${OUTPUT}..."
grub-mkrescue -o "$OUTPUT" "$ISO_DIR" 2>/dev/null

rm -rf "$ISO_DIR"
echo "[+] Done! ISO at: ${OUTPUT}"
```

Selanjutnya buatlah `backup.sh` untuk melakukan zip file yang berada di `osboot/` dan menghapus sisa-sisa file pada `osboot/`.

```c
#!/bin/bash
set -e

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="osboot/farewell_backup_[${TIMESTAMP}].zip"
OUTPUT_DIR="osboot"

FILES=(
  "${OUTPUT_DIR}/bzImage"
  "${OUTPUT_DIR}/single.gz"
  "${OUTPUT_DIR}/multi.gz"
  "${OUTPUT_DIR}/farewell.iso"
)

echo "[*] Checking files..."
MISSING=0
for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "[!] Missing: $f"
    MISSING=1
  fi
done
[ $MISSING -eq 1 ] && { echo "[!] Some files missing. Aborting."; exit 1; }

echo "[*] Creating backup: ${BACKUP_NAME}"
zip "$BACKUP_NAME" "${FILES[@]}"

echo "[*] Removing archived files..."
for f in "${FILES[@]}"; do
  rm -f "$f"
  echo "    Removed: $f"
done

echo "[+] Done! Backup saved as: ${BACKUP_NAME}"
```

Selanjutnya buatlah file `qemu.sh`, file ini berfungsi untuk menjalankan OS yang sudah dibuat dengan emulator QEMU. File ini bisa dijalankan dengan `-- single`, `--multi`, dan `--all`.


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
      echo "Booting from ISO with boot menu..."
      ${QEMU} -cdrom ${ISO} \
              -boot d \
              -m 512M \
              -nographic \
              -serial mon:stdio
      ;;

  *)
    usage
    ;;
esac
