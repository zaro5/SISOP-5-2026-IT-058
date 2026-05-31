#!/bin/bash
# multi.sh - Buat multi-user filesystem dengan BusyBox

set -e

FS_DIR="rootfs_multi"
OUTPUT_DIR="osobot"
OUTPUT_FILE="${OUTPUT_DIR}/multi.gz"

# Password hashes (dibuat dengan openssl passwd -1)
# root123, henn123, hann123, viii123, kids123
ROOT_HASH='$1$l7iUXgif$iNbfjxcn7XDio9KmEBrlY1'  
HENN_HASH='$1$xxGOrYdg$ngRRgPPmGUhwy9nuIW6tP1'  
HANN_HASH='$1$prqUULel$/1arsItfFVmOxYjib0ACE1'  
VIII_HASH='$1$2KpWnpZ/$Kn0yHF7itAjXHEW.CDuIa0'  
KIDS_HASH='$1$RO1UYqFT$Eu9lpDf63JektldhzHsO10'  

# Bersihkan direktori sebelumnya
rm -rf "${FS_DIR}"
mkdir -p "${FS_DIR}"

# Buat struktur direktori
mkdir -p "${FS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "${FS_DIR}/home"/{henn,hann,viii,kids}

# Copy busybox
cp /usr/bin/busybox "${FS_DIR}/bin/"

# Install busybox
cd "${FS_DIR}/bin"
./busybox --install .
cd ../..

# Buat file passwd
cat > "${FS_DIR}/etc/passwd" << EOF
root:${ROOT_HASH}:0:0:root:/root:/bin/sh
henn:${HENN_HASH}:1001:1001:henn:/home/henn:/bin/sh
hann:${HANN_HASH}:1002:1002:hann:/home/hann:/bin/sh
viii:${VIII_HASH}:1003:1003:viii:/home/viii:/bin/sh
kids:${KIDS_HASH}:1004:1004:kids:/home/kids:/bin/sh
EOF

# Buat file group
cat > "${FS_DIR}/etc/group" << EOF
root:x:0:root
henn:x:1001:henn
hann:x:1002:hann
viii:x:1003:viii
kids:x:1004:kids
wheel:x:10:root,henn,hann,viii,kids
users:x:100:henn,hann,viii,kids
EOF

# Buat file inittab
cat > "${FS_DIR}/etc/inittab" << 'EOF'
::sysinit:/bin/mount -t proc none /proc
::sysinit:/bin/mount -t sysfs none /sys
::sysinit:/bin/mount -t devtmpfs none /dev
tty1::respawn:/sbin/getty -L tty1 115200 vt100
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# Buat file profile (banner login)
cat > "${FS_DIR}/etc/profile" << 'EOF'
#!/bin/sh

# ASCII Art Farewell Party
cat << "BANNER"
   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \
 `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-'
  ___               _   _             
 | __|__ _ _ _ _ __| |_(_)_ _  ___ ___ 
 | _|/ _` | '_| '  \  _| | ' \/ -_|_-< 
 |_| \__,_|_| |_|_|_\__|_|_||_\___/__/
                                         
        Farewell Party
=========================================
Welcome, ${USER}!
=========================================
BANNER

export PATH=/bin:/sbin:/usr/bin
export PS1='[\u@\h:\w]\$ '
EOF

chmod +x "${FS_DIR}/etc/profile"

# Buat file init
cat > "${FS_DIR}/init" << 'EOF'
#!/bin/sh
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys
/bin/mount -t devtmpfs none /dev

# Switch ke multi-user init
exec /sbin/init
EOF

chmod +x "${FS_DIR}/init"

# Buat device nodes
cd "${FS_DIR}/dev"
mknod -m 666 console c 5 1 2>/dev/null || true
mknod -m 666 null c 1 3 2>/dev/null || true
mknod -m 666 tty1 c 4 1 2>/dev/null || true
mknod -m 620 ttyS0 c 4 64 2>/dev/null || true
cd ../..

# Set permissions sesuai specs
chmod 750 "${FS_DIR}/root"
chmod 755 "${FS_DIR}/home/henn"
chmod 750 "${FS_DIR}/home/hann"
chmod 750 "${FS_DIR}/home/viii"
chmod 700 "${FS_DIR}/home/kids"

# Buat initramfs
cd "${FS_DIR}"
find . | cpio -oHnewc | gzip > "../${OUTPUT_FILE}"
cd ..

# Hapus file sisa
rm -rf "${FS_DIR}"

echo "[*] Multi-user filesystem created at ${OUTPUT_FILE}"