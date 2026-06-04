#!/bin/bash
set -e

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="farewell_backup_[${TIMESTAMP}].zip"
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