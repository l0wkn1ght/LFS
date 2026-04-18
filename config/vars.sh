#!/bin/bash
# vars.sh - Global Variables
set -euo pipefail

export DEVICE="/dev/sda"
export EFI_PART="${DEVICE}1"
export SWAP_PART="${DEVICE}2"
export ROOT_PART="${DEVICE}3"

export LFS="/mnt/lfs"
export LFS_TGT="x86_64-lfs-linux-gnu"
export SOURCES_DIR="${LFS}/sources"
export TOOLS_DIR="${LFS}/tools"

export MAKEFLAGS="-j4"
export CFLAGS="-O2 -pipe -march=native"
export CXXFLAGS="${CFLAGS}"
export MKFLAGS="${MAKEFLAGS}"

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "Error: Must be root." >&2
        exit 1
    fi
}

confirm_action() {
    local msg="$1"
    read -r -p "${msg} [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

select_disk() {
    if [[ ! -t 0 ]]; then
        echo "Error: Not a terminal." >&2
        exit 1
    fi
    
    local disks=()
    local disk_info=()
    
    for dev in /dev/sd[a-z] /dev/nvme[0-9]n[0-9] /dev/vd[a-z]; do
        if [[ -b "${dev}" ]]; then
            local devname size
            devname=$(basename "${dev}")
            size=$(lsblk -dn -o SIZE -b "${dev}" 2>/dev/null | head -1)
            disks+=("${devname}")
            disk_info+=("${size:-Unknown}")
        fi
    done
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        echo "Error: No disks found." >&2
        exit 1
    fi
    
    if [[ ${#disks[@]} -eq 1 ]]; then
        echo "Only one disk found: ${disks[0]}"
        export DEVICE="/dev/${disks[0]}"
        return 0
    fi
    
    local selected=0
    local max_idx=$((${#disks[@]} - 1))
    
    while true; do
        printf "\033[2J\033[H"
        echo ""
        echo "============================================================"
        echo "                    AVAILABLE DISKS"
        echo "============================================================"
        printf "| %-15s | %-35s |\n" "DEVICE" "SIZE"
        printf "|%-17s|%-37s|\n" "---------------" "-----------------------------------"
        
        for i in "${!disks[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf "|> %-13s | %-35s |\n" "${disks[$i]}" "${disk_info[$i]}"
            else
                printf "|  %-13s | %-35s |\n" "${disks[$i]}" "${disk_info[$i]}"
            fi
        done
        printf "|%-17s|%-37s|\n" "---------------" "-----------------------------------"
        echo ""
        echo "Use UP/DOWN arrows to navigate, ENTER to select:"
        
        local key
        IFS= read -r -n 1 -t 5 key || true
        
        if [[ "${key}" == $'\e' ]]; then
            read -r -n 2 -t 0.1 key || true
            case "${key}" in
                $'\e[A')
                    if [[ $selected -gt 0 ]]; then ((selected--)); fi
                    ;;
                $'\e[B')
                    if [[ $selected -lt $max_idx ]]; then ((selected++)); fi
                    ;;
            esac
        elif [[ "${key}" == "" ]]; then
            break
        fi
    done
    
    echo ""
    echo "Selected: /dev/${disks[$selected]}"
    export DEVICE="/dev/${disks[$selected]}"
}

set_partitions() {
    if [[ -z "${DEVICE}" ]]; then
        echo "Error: DEVICE not set. Call select_disk() first." >&2
        return 1
    fi
    export DEVICE_NAME="${DEVICE}"
    export EFI_PART="${DEVICE}1"
    export SWAP_PART="${DEVICE}2"
    export ROOT_PART="${DEVICE}3"
}