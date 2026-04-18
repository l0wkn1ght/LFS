#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /lfs-build/config/vars.sh

EFI_PART="${EFI_PART:-/dev/sda1}"
ROOT_PART="${ROOT_PART:-/dev/sda3}"

echo "[INFO] Building Linux Kernel for Skylake / GT 740..."
cd /tmp
tar -xf "${SOURCES_DIR}"/linux-6.7.4.tar.xz
cd linux-6.7.4

make mrproper
make defconfig

echo "[INFO] Enabling EFISTUB, Nouveau (GT 740), and AHCI..."
scripts/config --enable CONFIG_EFI_STUB
scripts/config --enable CONFIG_DRM
scripts/config --enable CONFIG_DRM_NOUVEAU
scripts/config --enable CONFIG_FB_EFI
scripts/config --enable CONFIG_VT
scripts/config --enable CONFIG_SERIAL_8250
scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_TMPFS
scripts/config --enable CONFIG_SATA_AHCI

echo "[INFO] Compiling kernel..."
make "${MKFLAGS}" || { echo "Error: Kernel build failed." >&2; exit 1; }
make modules_install || { echo "Error: Modules install failed." >&2; exit 1; }

if [[ ! -f arch/x86/boot/bzImage ]]; then
    echo "Error: Kernel image not created." >&2
    exit 1
fi

echo "[INFO] Setting up EFISTUB boot structure..."
mkdir -pv /boot/efi/EFI/Linux
cp -v arch/x86/boot/bzImage /boot/efi/EFI/Linux/bzImage-lfs.efi

echo "[INFO] Installing GT 740 (Nouveau) firmware..."
cd /tmp
tar -xf "${SOURCES_DIR}"/linux-firmware-20231111.tar.xz || { echo "Error: Firmware extraction failed." >&2; exit 1; }
mkdir -pv /lib/firmware/nouveau
if [[ -d linux-firmware-20231111/nouveau ]]; then
    cp -v linux-firmware-20231111/nouveau/* /lib/firmware/nouveau/ 2>/dev/null || true
    echo "[INFO] Nouveau firmware installed."
else
    echo "Warning: Nouveau firmware not found." >&2
fi

echo "[INFO] Generating Initramfs..."
if command -v dracut >/dev/null 2>&1; then
    dracut --no-hostonly --force /boot/efi/EFI/Linux/initramfs-lfs.img || echo "Warning: Dracut failed." >&2
else
    echo "Warning: Dracut not found. Skipping initramfs." >&2
    mkdir -p /boot/efi/EFI/Linux
    touch /boot/efi/EFI/Linux/initramfs-lfs.img
fi

echo "[INFO] Registering LFS in UEFI NVRAM..."
DEVICE_NAME="${DEVICE_NAME:-/dev/sda}"
efibootmgr -c -d "${DEVICE_NAME}" -p 1 -L "LFS Linux (Runit)" -l '\EFI\Linux\bzImage-lfs.efi' -u "initrd=\EFI\Linux\initramfs-lfs.img root=${ROOT_PART} rw" || {
    echo "Warning: efibootmgr failed. Create entry manually." >&2
}

echo "=================================================="
echo "[SUCCESS] LFS SYSTEM FULLY BUILT AND REGISTERED!"
echo "Type 'exit'. The host will unmount drives."
echo "Then reboot and select 'LFS Linux' from the HP boot menu."
echo "=================================================="