#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source ../config/vars.sh
check_root

if ! ping -c 1 -W 5 www.linuxfromscratch.org >/dev/null 2>&1 && \
   ! ping -c 1 -W 5 cdn.kernel.org >/dev/null 2>&1; then
    echo "Warning: Cannot reach internet. Checking sources anyway..." >&2
fi

echo "[INFO] Creating LFS directory tree..."
mkdir -pv "${SOURCES_DIR}"
chmod -v a+wt "${SOURCES_DIR}"
mkdir -pv "${TOOLS_DIR}"
ln -sv "${TOOLS_DIR}" /

echo "[INFO] Downloading LFS base sources (stable)..."
if ! wget --input-file=https://www.linuxfromscratch.org/lfs/views/stable/wget-list-sysv \
     --continue --directory-prefix="${SOURCES_DIR}"; then
    echo "Error: Failed to download LFS source list" >&2
    exit 1
fi

echo "[INFO] Downloading hardware-specific sources..."
cd "${SOURCES_DIR}"

download_and_verify() {
    local url="$1"
    local filename="$2"
    if [[ -f "${filename}" ]]; then
        echo "[INFO] ${filename} already exists, skipping..."
        return 0
    fi
    if wget -nv --show-progress -c -O "${filename}" "${url}"; then
        echo "[INFO] Downloaded: ${filename}"
    else
        echo "Error: Failed to download ${filename}" >&2
        return 1
    fi
}

download_and_verify "https://github.com/skarnetsoftware/runit/archive/refs/tags/v2.1.2.tar.gz" "runit-2.1.2.tar.gz"
download_and_verify "https://github.com/networkmanager/dhcpcd/releases/download/v10.0.1/dhcpcd-10.0.1.tar.xz" "dhcpcd-10.0.1.tar.xz"
download_and_verify "https://cdn.kernel.org/pub/linux/kernel/firmware/linux-firmware-20231111.tar.xz" "linux-firmware-20231111.tar.xz"
download_and_verify "https://github.com/rhboot/efibootmgr/releases/download/18/efibootmgr-18.tar.gz" "efibootmgr-18.tar.gz"

echo "[INFO] Verifying source downloads..."
if (( $(printf '%s\n' ./*.tar.* 2>/dev/null | wc -l) < 3 )); then
    echo "Error: Insufficient source files downloaded" >&2
    exit 1
fi

echo "[SUCCESS] Sources downloaded."