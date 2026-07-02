# Kore OS

A minimal, clean, secure Linux operating system with KDE Plasma.

**Created by Josh Clark and Steven Quintero** — [wsgpolar.me](https://wsgpolar.me) / [pro42good.me](https://pro42good.me)

---

## Features

- **Minimal** — Clean KDE Plasma desktop with only essential applications
- **Smooth Animations** — Animated Plymouth boot splash, fluid KDE compositing
- **Secure** — UFW firewall, AppArmor, fail2ban, hardened defaults
- **Beautiful** — Custom dark theme, clean layout, custom login screen
- **Universal** — Runs on UTM, VirtualBox, VMware, and bare metal

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores (x86_64 or aarch64) | 4+ cores |
| RAM | 2 GB | 4+ GB |
| Disk | 16 GB | 32+ GB |
| Graphics | Any GPU with KMS support | NVIDIA/AMD/Intel |

## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (macOS/Windows) or Docker (Linux)
- At least 10 GB free disk space for the build

### Build the ISO

```bash
# Clone the repository
git clone https://github.com/polardev-ui/kore.git
cd koreos

# Build the x86_64 ISO
make build-x86_64

# Or build all architectures
make build

# The ISO will be in output/
```

### Run in a VM

1. Build the ISO with `make build-x86_64`
2. Create a new VM:
   - **UTM**: Create QEMU VM, attach the ISO, boot
   - **VirtualBox**: Create new VM, attach the ISO, boot
   - **VMware**: Create new VM, attach the ISO, boot
3. Boot from the ISO and select "Kore OS Live"
4. To install, launch the "Install Kore OS" desktop shortcut

## Build Options

```bash
make build-x86_64    # Build x86_64 ISO (recommended)
make build-aarch64   # Build ARM64 disk image
make build           # Build both
make shell           # Open shell in build environment
make clean           # Clean build artifacts
```

## Installation

1. Boot the live ISO
2. Click "Install Kore OS" on the desktop
3. Follow the Calamares installer prompts:
   - Select language/timezone
   - Partition your disk (or use guided partitioning)
   - Create a user account
   - Install GRUB bootloader
4. Reboot and enjoy Kore OS

## Security

Kore OS comes with security out of the box:

- **UFW Firewall** — Enabled by default, deny incoming
- **AppArmor** — Enforcing mode
- **Fail2ban** — Protects against brute force attacks
- **Secure defaults** — No root login, sudo configuration
- **Encryption support** — LUKS available during installation
- **Hardened sysctl** — Kernel security parameters optimized

## Credits

- **Josh Clark** — Creator & Developer ([wsgpolar.me](https://wsgpolar.me))
- **Steven Quintero** — Co-Creator & Software Engineer ([pro42good.me](https://pro42good.me))
- Built with Debian 13 Trixie, KDE Plasma, and Calamares
- Licensed under GPL v3
