# Kore OS on Raspberry Pi

## Supported Models
- Raspberry Pi 5 (recommended)
- Raspberry Pi 4 Model B
- Raspberry Pi 3 Model B+

## Installation

### Method 1: Flash the image
1. Download `koreos-aarch64.img.xz`
2. Flash to an SD card (16GB+ recommended):
   ```bash
   xz -d koreos-aarch64.img.xz
   sudo dd if=koreos-aarch64.img of=/dev/sdX bs=4M status=progress
   sync
   ```
3. Insert SD card into the Pi and boot

### Method 2: Manual installation
1. Install Arch Linux ARM following the official guide
2. Add the Kore OS repositories and install the meta-package

## Post-Install
After first boot, run:
```bash
sudo kore-firstboot.sh
```

This configures the desktop environment and applies branding.
