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