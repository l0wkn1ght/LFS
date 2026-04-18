#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source ../config/vars.sh
# shellcheck disable=SC1091
source ../config/build_helpers.sh

if [[ "$(whoami)" != "lfs" ]]; then
    echo "Error: Must be run as 'lfs' user." >&2
    exit 1
fi

if [[ -z "${LFS:-}" ]] || [[ ! -d "${LFS}" ]]; then
    echo "Error: LFS variable not set or directory not found." >&2
    exit 1
fi

cleanup_tmp() {
    cd / 2>/dev/null || true
    rm -rf /tmp/gcc-* /tmp/linux-* /tmp/glibc-* 2>/dev/null || true
}
trap cleanup_tmp EXIT

echo "[INFO] Starting Chapter 5: Cross-Compilation Toolchain..."

echo "[BUILD] Binutils Pass 1..."
build_pkg "binutils-2.42" "--prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --enable-gprofng=no --disable-werror --newlib"

if [[ ! -f "${LFS}/tools/bin/ld" ]]; then
    echo "Error: Binutils not installed correctly." >&2
    exit 1
fi

echo "[BUILD] GCC Pass 1 (with prerequisites)..."
tar -xf "${SOURCES_DIR}"/gcc-13.2.0.tar.xz -C /tmp
cd /tmp/gcc-13.2.0 || { echo "Error: Failed to extract GCC." >&2; exit 1; }
if tar -xf "${SOURCES_DIR}"/mpfr-4.2.1.tar.xz; then
    mv -v mpfr-4.2.1 mpfr
else
    echo "Error: Failed to extract mpfr." >&2
    exit 1
fi
if tar -xf "${SOURCES_DIR}"/gmp-6.3.0.tar.xz; then
    mv -v gmp-6.3.0 gmp
else
    echo "Error: Failed to extract gmp." >&2
    exit 1
fi
if tar -xf "${SOURCES_DIR}"/mpc-1.3.1.tar.gz; then
    mv -v mpc-1.3.1 mpc
else
    echo "Error: Failed to extract mpc." >&2
    exit 1
fi
cd /
build_pkg "gcc-13.2.0" "--target=$LFS_TGT --prefix=$LFS/tools --with-sysroot=$LFS --with-newlib --without-headers --disable-shared --disable-multilib --disable-threads --disable-libssp --enable-languages=c,c++"

if [[ ! -f "${LFS}/tools/bin/${LFS_TGT}-gcc" ]]; then
    echo "Error: GCC not installed correctly." >&2
    exit 1
fi

echo "[BUILD] Linux API Headers..."
cd /tmp
tar -xf "${SOURCES_DIR}"/linux-6.7.4.tar.xz
cd linux-6.7.4 || { echo "Error: Failed to extract Linux headers." >&2; exit 1; }
make mrproper
make headers
find usr/include -name '.*' -delete
cp -rv usr/include "${LFS}/usr" || { echo "Error: Failed to install headers." >&2; exit 1; }
cd /
rm -rf /tmp/linux-6.7.4

if [[ ! -d "${LFS}/usr/include" ]]; then
    echo "Error: Linux headers not installed." >&2
    exit 1
fi

echo "[BUILD] Glibc..."
build_pkg "glibc-2.39" "--prefix=/tools --host=$LFS_TGT --enable-kernel=4.19 --with-headers=$LFS/usr/include libc_cv_slibdir=/tools/lib"

if [[ ! -f /tools/lib/libc.so ]]; then
    echo "Error: Glibc not installed correctly." >&2
    exit 1
fi

echo "[BUILD] Libstdc++ Pass 2..."
build_pkg "gcc-13.2.0" "--target=$LFS_TGT --prefix=$LFS/tools --disable-nls --enable-shared --disable-multilib --disable-threads --disable-libssp --enable-languages=c,c++"

echo "[INFO] Testing cross-toolchain..."

echo 'int main(){}' | "$LFS_TGT"-gcc -xc - -o /tmp/test_cross 2>/dev/null || { echo "Error: Cross-compiler test failed." >&2; exit 1; }
readelf -l /tmp/test_cross | grep -q interpreter && echo "[SUCCESS] Toolchain functional!"

if readelf -l /tmp/test_cross | grep -q "ld-linux"; then
    echo "[SUCCESS] Cross-toolchain verified!"
else
    echo "Error: Cross-toolchain verification failed." >&2
    rm -f /tmp/test_cross
    exit 1
fi
rm -f /tmp/test_cross

echo "[SUCCESS] Toolchain build complete!"