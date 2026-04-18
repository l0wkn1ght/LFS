#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /lfs-build/config/vars.sh
# shellcheck disable=SC1091
source /lfs-build/config/build_helpers.sh

echo "[INFO] Starting Chapter 6: Base System Installation..."

mkdir -pv /{etc,var} /usr/{bin,lib,sbin}
for i in bin lib sbin; do ln -sv usr/$i /$i; done
case $(uname -m) in x86_64) mkdir -pv /lib64 ;; esac

for dir in /etc /var /usr/bin /usr/lib; do
    if [[ ! -d "${dir}" ]]; then
        echo "Error: Failed to create ${dir}" >&2
        exit 1
    fi
done

echo "[BUILD] Installing Glibc..."
build_pkg "glibc-2.39" "--prefix=/usr --disable-werror --enable-kernel=4.19 --enable-add-ons libc_cv_slibdir=/usr/lib"

echo "[BUILD] Installing Zstd..."
build_pkg "zstd-1.5.6" "--prefix=/usr --disable-static"

echo "[BUILD] Installing Binutils..."
build_pkg "binutils-2.42" "--prefix=/usr --sysconfdir=/etc --enable-gold --enable-default-gold --disable-nls --disable-werror"

echo "[BUILD] Installing GCC..."
build_pkg "gcc-13.2.0" "--prefix=/usr --enable-languages=c,c++ --disable-multilib --disable-bootstrap"

# YAGNI: Add more packages here (bash, coreutils, diffutils, gawk, findutils, groff, gzip, iproute2, kbd, kmod, libtool, make, man-db, procps-ng, readline, sed, shadow, tar, texinfo, util-linux)

echo "[BUILD] Installing DHCPCD..."
build_pkg "dhcpcd-10.0.1" "--prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib/dhcpcd --dbdir=/var/lib/dhcpcd"

echo "[BUILD] Installing EFIBOOTMGR..."
build_pkg "efibootmgr-18" "" || echo "Warning: efibootmgr skipped (efivar dependency missing)"

echo "[INFO] Base system complete. Chaining to runit_setup.sh..."
exec /bin/bash /lfs-build/chroot/runit_setup.sh