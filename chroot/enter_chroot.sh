#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source ../config/vars.sh
check_root

if [[ ! -d "${LFS}" ]]; then
    echo "Error: LFS directory ${LFS} not found. Run partition.sh first." >&2
    exit 1
fi

if [[ "$(stat -c %d /)" == "$(stat -c %d "${LFS}" 2>/dev/null || echo "0")" ]]; then
    if grep -q/aes/ /proc/cmdline 2>/dev/null || [[ -f /.lfs_in_chroot ]]; then
        echo "Error: Already in chroot environment." >&2
        exit 1
    fi
fi

echo "[INFO] Mounting virtual kernel file systems..."
mount -v --bind /dev "${LFS}/dev" || { echo "Error: Failed mount /dev." >&2; exit 1; }
mount -vt devpts devpts "${LFS}/dev/pts" -o gid=5,mode=0620 || { echo "Error: Failed mount devpts." >&2; exit 1; }
mount -vt proc proc "${LFS}/proc" || { echo "Error: Failed mount proc." >&2; exit 1; }
mount -vt sysfs sysfs "${LFS}/sys" || { echo "Error: Failed mount sysfs." >&2; exit 1; }
mount -vt tmpfs tmpfs "${LFS}/run" || { echo "Error: Failed mount tmpfs." >&2; exit 1; }

# shellcheck disable=SC2155
export BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -pv "${LFS}"/lfs-build
mount -v --bind "${BUILD_DIR}" "${LFS}/lfs-build" || { echo "Error: Failed mount build dir." >&2; exit 1; }

touch /.lfs_in_chroot

echo "[INFO] Entering Chroot..."
if ! chroot "${LFS}" /usr/bin/env -i   \
    HOME=/root                    \
    TERM="${TERM}"                \
    PS1='(chroot) \u:\w\$ '       \
    PATH=/usr/bin:/usr/sbin       \
    MAKEFLAGS="${MKFLAGS}"        \
    LFS=/lfs-build                \
    /bin/bash /lfs-build/chroot/base_system.sh; then
    echo "Error: Chroot build failed." >&2
    exit 1
fi

echo "[INFO] Exiting Chroot..."
umount -Rv "${LFS}"/lfs-build
umount -Rv "${LFS}"/dev/pts
umount -Rv "${LFS}"/dev
umount -Rv "${LFS}"/proc
umount -Rv "${LFS}"/sys
umount -Rv "${LFS}"/run

rm -f /.lfs_in_chroot

echo "[SUCCESS] Build finished. You can reboot now."