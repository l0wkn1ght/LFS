#!/bin/bash
# main.sh - LFS Build Orchestrator
set -euo pipefail

cd "$(dirname "$0")"

echo "=============================================="
echo "           LFS BUILD START (Tracking Stable)"
echo "=============================================="
echo ""

# Step 1: Partition
echo "[STEP 1/6] Partitioning disk..."
bash host_root/partition.sh

# Step 2: Download sources
echo ""
echo "[STEP 2/6] Downloading sources..."
bash host_root/sources_tree.sh

# Step 3: Create lfs user
echo ""
echo "[STEP 3/6] Creating lfs user..."
bash host_root/create_user.sh

# Step 4: Build toolchain as lfs user
echo ""
echo "[STEP 4/6] Building toolchain (switching to lfs user)..."
echo "Press Enter to continue as lfs user..."
read -r
su - lfs -c "cd $(pwd) && bash lfs_user/toolchain.sh"

# Step 5: Enter chroot
echo ""
echo "[STEP 5/6] Entering chroot for base system build..."
echo "Press Enter to continue..."
read -r
bash chroot/enter_chroot.sh

echo ""
echo "=============================================="
echo "           BUILD COMPLETE"
echo "=============================================="
echo "Run 'reboot' to boot into your LFS system."
echo "Select 'LFS Linux (Runit)' from UEFI boot menu."
echo "=============================================="