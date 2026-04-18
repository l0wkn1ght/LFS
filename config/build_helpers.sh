#!/bin/bash
# build_helpers.sh - DRY Compilation Engine
set -euo pipefail

build_pkg() {
    local pkg="$1"
    local configure_cmd="$2"
    
    if [[ -z "${SOURCES_DIR:-}" ]]; then
        echo "Error: SOURCES_DIR not set." >&2
        return 1
    fi
    if [[ ! -d "${SOURCES_DIR}" ]]; then
        echo "Error: SOURCES_DIR (${SOURCES_DIR}) does not exist." >&2
        return 1
    fi
    
    echo "[BUILD] Starting: ${pkg}"
    
    local archive
    archive=$(find "${SOURCES_DIR}" -maxdepth 1 -name "${pkg}.tar.*" -type f 2>/dev/null | head -n1)
    if [[ -z "${archive}" ]]; then
        echo "Error: Source archive for ${pkg} not found." >&2
        return 1
    fi
    
    tar -xf "${archive}" -C /tmp
    if [[ -d "/tmp/${pkg}" ]]; then
        cd "/tmp/${pkg}" || { echo "Error: Cannot cd to /tmp/${pkg}." >&2; return 1; }
    else
        tar -xf "${archive}" -C /tmp --strip-components=1
        cd "/tmp/${pkg}" || { echo "Error: Cannot cd to /tmp/${pkg}." >&2; return 1; }
    fi
    
    if [[ -f configure ]]; then
        echo "[BUILD] Configuring ${pkg}..."
        # shellcheck disable=SC2086
        eval "${configure_cmd}" || { echo "Error: Configure failed." >&2; return 1; }
    fi
    
    echo "[BUILD] Compiling ${pkg}..."
    # shellcheck disable=SC2086
    make ${MAKEFLAGS:-"-j4"} || { echo "Error: Make failed." >&2; return 1; }
    
    echo "[BUILD] Installing ${pkg}..."
    make install || true
    
    cd / || true
    rm -rf "/tmp/${pkg}"
    echo "[BUILD] Finished: ${pkg}"
}