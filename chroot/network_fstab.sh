#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /lfs-build/config/vars.sh

EFI_PART="${EFI_PART:-/dev/sda1}"
SWAP_PART="${SWAP_PART:-/dev/sda2}"
ROOT_PART="${ROOT_PART:-/dev/sda3}"

echo "[INFO] Setting up /etc/fstab..."
cat > /etc/fstab << EOF
# <device>      <mount point>   <type>   <options>       <dump>  <fsck>
${EFI_PART}       /boot/efi       vfat     defaults        0       0
${SWAP_PART}    swap            swap     pri=1           0       0
${ROOT_PART}    /               ext4     defaults        1       1
proc            /proc           proc     nosuid,noexec,nodev 0    0
sysfs           /sys            sysfs    nosuid,noexec,nodev 0    0
tmpfs           /run            tmpfs    defaults        0       0
devpts          /dev/pts        devpts   gid=5,mode=620  0       0
EOF

echo "prodesk-lfs" > /etc/hostname

cat > /etc/hosts << EOF
127.0.0.1   localhost.localdomain   localhost
::1         localhost.localdomain   localhost
EOF

echo "[INFO] Creating dhcpcd service..."
mkdir -pv /etc/service/dhcpcd
cat > /etc/service/dhcpcd/run << "EOF"
#!/bin/sh
exec /usr/sbin/dhcpcd -B
EOF
chmod +x /etc/service/dhcpcd/run

mkdir -pv /var/log/dhcpcd

echo "[INFO] Network configured. Chaining to kernel_efistub.sh..."
exec /bin/bash /lfs-build/chroot/kernel_efistub.sh