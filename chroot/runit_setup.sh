#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /lfs-build/config/vars.sh
# shellcheck disable=SC1091
source /lfs-build/config/build_helpers.sh

EFI_PART="${EFI_PART:-/dev/sda1}"

echo "[INFO] Installing Runit..."
tar -xf "${SOURCES_DIR}"/runit-2.1.2.tar.gz -C /tmp || { echo "Error: Failed extract runit." >&2; exit 1; }
cd /tmp/runit-2.1.2
package/compile || { echo "Error: Failed compile runit." >&2; exit 1; }
package/install || { echo "Error: Failed install runit." >&2; exit 1; }
cd /
rm -rf /tmp/runit-2.1.2

if [[ ! -x /usr/sbin/runsvdir ]]; then
    echo "Error: Runit not installed." >&2
    exit 1
fi

echo "[INFO] Creating Runit stage scripts..."
mkdir -pv /etc/runit/runsvdir/default

cat > /etc/runit/1 << EOF
#!/bin/sh
/bin/mount -t proc proc /proc || /bin/true
/bin/mount -t sysfs sysfs /sys || /bin/true
/bin/mount -t devpts devpts /dev/pts -o gid=5,mode=620 || /bin/true
/bin/mount -t tmpfs tmpfs /run || /bin/true
/bin/mount ${EFI_PART} /boot/efi || /bin/true
EOF
chmod +x /etc/runit/1

cat > /etc/runit/2 << EOF
#!/bin/sh
exec /usr/sbin/runsvdir -P /etc/service
EOF
chmod +x /etc/runit/2

cat > /etc/runit/3 << EOF
#!/bin/sh
echo "System is going down..."
/usr/sbin/runsvchdir stop || /bin/true
/bin/sync
/bin/umount -a -r || /bin/true
EOF
chmod +x /etc/runit/3

echo "[INFO] Runit initialized. Chaining to network_fstab.sh..."
exec /bin/bash /lfs-build/chroot/network_fstab.sh