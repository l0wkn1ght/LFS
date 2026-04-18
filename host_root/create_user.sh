#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source ../config/vars.sh
check_root

if id -u lfs >/dev/null 2>&1; then
    echo "[INFO] User 'lfs' already exists. Adjusting..."
    usermod -g lfs -G audio,video lfs 2>/dev/null || true
else
    echo "[INFO] Creating 'lfs' user..."
    SKEL_DIR=$(mktemp -d)
    trap 'rm -rf "${SKEL_DIR}"' EXIT
    
    groupadd lfs 2>/dev/null || true
    useradd -s /bin/bash -g lfs -d /home/lfs -m -k "${SKEL_DIR}" lfs
    
    if [[ -t 0 ]]; then
        passwd lfs
    else
        usermod -p '!' lfs
        chage -d 0 lfs
    fi
fi

chown -v lfs:lfs "${TOOLS_DIR}"
chown -v lfs:lfs "${SOURCES_DIR}"

echo "[INFO] Configuring environment for 'lfs' user..."
cat > /home/lfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash --login
EOF

cat > /home/lfs/.bashrc << "EOF"
set +h
umask 022
export LFS="${LFS}"
export LC_ALL=POSIX
export LFS_TGT="${LFS_TGT}"
export MAKEFLAGS="${MKFLAGS:-}"
if [[ -z "${TOOLS_DIR:-}" ]]; then
    export PATH=/usr/bin:/bin
else
    export PATH="${TOOLS_DIR}/bin":/usr/bin:/bin
fi
export CONFIG_SITE="${LFS}/usr/share/config.site"
echo "LFS build environment configured."
echo "LFS: ${LFS}"
echo "LFS_TGT: ${LFS_TGT}"
echo "MAKEFLAGS: ${MAKEFLAGS}"
EOF

chown -v lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
chmod -v 644 /home/lfs/.bash_profile /home/lfs/.bashrc

echo "[SUCCESS] User 'lfs' created. Run 'su - lfs' now."