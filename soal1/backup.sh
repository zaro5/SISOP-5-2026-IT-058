#!/bin/bash
# backup.sh - Backup semua hasil build ke zip

set -e

OUTPUT_DIR="osobot"
BACKUP_NAME="farewell_backup_$(date +%d%m%Y-%H%M%S).zip"

# Pindah ke direktori osobot
cd "${OUTPUT_DIR}"

# Zip semua file
zip -9 "../${BACKUP_NAME}" \
    bzImage \
    single.gz \
    multi.gz \
    farewell.iso 2>/dev/null || true

# Hapus file asli setelah backup (sesuai specs)
rm -f bzImage single.gz multi.gz farewell.iso

cd ..

echo "[*] Backup created: ${BACKUP_NAME}"
echo "[*] Original build files deleted from osobot/"
