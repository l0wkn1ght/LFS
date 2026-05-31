#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/vars.sh"
check_root

echo "[INFO] Detecting available disks..."
select_disk
set_partitions

if [[ ! -b "${DEVICE}" ]]; then
    echo "Error: Device ${DEVICE} not found." >&2
    exit 1
fi

for part in "${SWAP_PART}" "${ROOT_PART}"; do
    if swapon --show "${part}" >/dev/null 2>&1; then
        echo "Error: ${part} is already swap." >&2
        exit 1
    fi
    if mountpoint -q "${part}"; then
        echo "Error: ${part} is already mounted." >&2
        exit 1
    fi
done

echo "=================================================="
echo "EFI (Win): ${EFI_PART}"
echo "Swap:      ${SWAP_PART}"
echo "Root:      ${ROOT_PART}"
echo "=================================================="
confirm_action "WARNING: This will DESTROY data on Swap and Root. Proceed?"

echo "[INFO] Partitioning disk..."
parted -a optimal "${DEVICE}" mklabel gpt || { echo "Error: Failed GPT" >&2; exit 1; }
parted -a optimal "${DEVICE}" mkpart primary linux-swap 1MiB 8193MiB || { echo "Error: Failed swap" >&2; exit 1; }
parted -a optimal "${DEVICE}" mkpart primary ext4 8193MiB 100% || { echo "Error: Failed root" >&2; exit 1; }
parted -a optimal "${DEVICE}" print

echo "[INFO] Creating filesystems..."
mkswap "${SWAP_PART}" || { echo "Error: Failed mkswap" >&2; exit 1; }
mkfs.ext4 -L "LFS_ROOT" "${ROOT_PART}" || { echo "Error: Failed mkfs" >&2; exit 1; }

echo "[INFO] Mounting..."
mkdir -pv "${LFS}"
mount -v -t ext4 "${ROOT_PART}" "${LFS}" || { echo "Error: Failed mount" >&2; exit 1; }
swapon "${SWAP_PART}" || { echo "Error: Failed swapon" >&2; exit 1; }

mountpoint -q "${LFS}" || { echo "Error: Not mounted" >&2; exit 1; }
swapon --show "${SWAP_PART}" >/dev/null || { echo "Error: Swap inactive" >&2; exit 1; }

echo "[SUCCESS] Partitions ready."
