# LFS Build Scripts (Tracking Stable)

Automated Linux From Scratch with Runit init system (tracking stable branch).

## Quick Start

```bash
sudo bash main.sh
```

## Manual Steps

| Step | Command | User |
|------|---------|------|
| 1 | `bash host_root/partition.sh` | root |
| 2 | `bash host_root/sources_tree.sh` | root |
| 3 | `bash host_root/create_user.sh` | root |
| 4 | `su - lfs` then `bash lfs_user/toolchain.sh` | lfs |
| 5 | `bash chroot/enter_chroot.sh` | root |

## Disk Selection

Interactive selector appears in partition.sh - use UP/DOWN arrows to choose disk.

## Files

```
LFS/
├── main.sh                    # Build orchestrator
├── config/
│   ├── vars.sh               # Variables & functions
│   └── build_helpers.sh      # Package builder
├── host_root/
│   ├── partition.sh          # Partition & mount
│   ├── sources_tree.sh       # Download sources
│   └── create_user.sh        # Create lfs user
├── lfs_user/
│   └── toolchain.sh          # Cross-toolchain
└── chroot/
    ├── enter_chroot.sh       # Enter chroot
    ├── base_system.sh       # Base packages
    ├── runit_setup.sh       # Install runit
    ├── network_fstab.sh     # Network config
    └── kernel_efistub.sh     # Build kernel
```

## Requirements

- x86_64 host with UEFI
- 8GB+ RAM recommended
- Root access
- Internet connection