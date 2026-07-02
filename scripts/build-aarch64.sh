#!/bin/bash
set -euo pipefail

echo "[Kore OS Builder] Setting up aarch64 build environment..."

# Clean up any stale loop devices from previous interrupted builds
for dev in /dev/loop*; do
  if [ -b "$dev" ]; then
    sudo losetup -d "$dev" 2>/dev/null || true
  fi
done

KORE_VERSION="${KORE_VERSION:-1.0.0}"
BUILD_DATE="${BUILD_DATE:-$(date -u +%Y%m%d)}"
WORK_DIR="/opt/koreos"
OUTPUT_DIR="${WORK_DIR}/output"
BUILD_ROOTFS="/tmp/koreos-aarch64-build"
IMAGE_MNT="/tmp/koreos-aarch64-mount"
ESP_DIR="/tmp/koreos-aarch64-esp"
TMP_ESP="/tmp/koreos-esp.img"
IMG_FILE="${OUTPUT_DIR}/koreos-${KORE_VERSION}-aarch64.img"
ESP_OFFSET=$((1 * 1024 * 1024))
ESP_SIZE_MB=512
ROOT_SIZE_MB=$((7680))
GPT_BACKUP_MB=1
ROOT_START_MB=$((1 + ESP_SIZE_MB))
ROOT_END_MB=$((ROOT_START_MB + ROOT_SIZE_MB))
TOTAL_MB=$((ROOT_END_MB + GPT_BACKUP_MB))
ROOT_OFFSET=$((ROOT_START_MB * 1024 * 1024))
ROOT_SIZE_BYTES=$((ROOT_SIZE_MB * 1024 * 1024))
ROOT_SIZE_KB=$((ROOT_SIZE_MB * 1024))
ESP_SIZE_BYTES=$((ESP_SIZE_MB * 1024 * 1024))

mkdir -p "${OUTPUT_DIR}" "${BUILD_ROOTFS}" "${IMAGE_MNT}" "${ESP_DIR}"

# ================================================================
# Phase 1: Build rootfs with debootstrap
# ================================================================
echo "[Kore OS Builder] Bootstrapping Debian Trixie arm64 rootfs..."

sudo rm -rf "${BUILD_ROOTFS:?}"/*
sudo debootstrap --arch=arm64 --foreign \
  --components=main,contrib,non-free-firmware \
  trixie "${BUILD_ROOTFS}" http://deb.debian.org/debian

sudo cp /usr/bin/qemu-aarch64-static "${BUILD_ROOTFS}/usr/bin/"
sudo DEBIAN_FRONTEND=noninteractive chroot "${BUILD_ROOTFS}" \
  /debootstrap/debootstrap --second-stage

echo "[Kore OS Builder] Configuring apt sources..."
sudo tee "${BUILD_ROOTFS}/etc/apt/sources.list" >/dev/null << 'SOURCES'
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
SOURCES

chroot_mount() {
  sudo mount -t proc none "${BUILD_ROOTFS}/proc"
  sudo mount -o bind /sys "${BUILD_ROOTFS}/sys"
  sudo mount -o bind /dev "${BUILD_ROOTFS}/dev"
  sudo mount -o bind /dev/pts "${BUILD_ROOTFS}/dev/pts"
  sudo rm -f "${BUILD_ROOTFS}/etc/resolv.conf"
  echo "nameserver 1.1.1.1" | sudo tee "${BUILD_ROOTFS}/etc/resolv.conf" >/dev/null
}

chroot_umount() {
  sudo umount "${BUILD_ROOTFS}/dev/pts" 2>/dev/null || true
  sudo umount "${BUILD_ROOTFS}/dev" 2>/dev/null || true
  sudo umount "${BUILD_ROOTFS}/sys" 2>/dev/null || true
  sudo umount "${BUILD_ROOTFS}/proc" 2>/dev/null || true
}
trap chroot_umount EXIT

chroot_mount

echo "[Kore OS Builder] Installing packages..."
sudo DEBIAN_FRONTEND=noninteractive chroot "${BUILD_ROOTFS}" /usr/bin/qemu-aarch64-static /bin/bash -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  # Kernel + firmware
  apt-get install -y \
    linux-image-arm64 linux-headers-arm64 \
    firmware-linux firmware-linux-nonfree firmware-brcm80211 firmware-realtek

  # Boot + init
  apt-get install -y \
    grub-efi-arm64 efibootmgr systemd systemd-sysv initramfs-tools plymouth plymouth-themes

  # Display server
  apt-get install -y \
    xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all \
    mesa-utils libgl1-mesa-dri mesa-vulkan-drivers

  # KDE Plasma desktop (full)
  apt-get install -y \
    kde-plasma-desktop plasma-nm plasma-pa sddm sddm-theme-breeze \
    kwin-x11 kwin-wayland powerdevil systemsettings kinfocenter     plasma-widgets-addons \
    plasma-systemmonitor kactivitymanagerd polkit-kde-agent-1 \
    kde-config-gtk-style kde-config-gtk-style-preview kde-config-sddm

  # KDE applications
  apt-get install -y \
    dolphin konsole kate gwenview     kde-spectacle okular kcalc ark kwrite kfind print-manager

  # Networking
  apt-get install -y \
    network-manager wpasupplicant openssh-server curl wget

  # Audio
  apt-get install -y \
    pipewire pipewire-pulse pipewire-alsa wireplumber

  # Security
  apt-get install -y \
    ufw apparmor apparmor-profiles apparmor-utils fail2ban auditd

  # Filesystems
  apt-get install -y \
    dosfstools e2fsprogs btrfs-progs exfatprogs ntfs-3g xfsprogs squashfs-tools \
    lvm2 cryptsetup udisks2

  # Utilities
  apt-get install -y \
    sudo nano htop fastfetch pciutils usbutils unzip     unrar-free p7zip zip rsync \
    bash-completion man-db man-pages xdg-user-dirs xdg-utils dbus-x11

  # Fonts
  apt-get install -y \
    fonts-noto fonts-noto-color-emoji fonts-dejavu fonts-liberation fonts-jetbrains-mono

  # Theming
  apt-get install -y \
    qt-style-kvantum qt5ct qt6ct breeze breeze-gtk-theme breeze-icon-theme

  # Installer + system tools
  apt-get install -y \
    calamares cups bluez bluez-obexd plymouth-label

  apt-get clean
  rm -rf /var/lib/apt/lists/*
' 2>&1 | tail -10

echo "[Kore OS Builder] Configuring services and user..."
sudo DEBIAN_FRONTEND=noninteractive chroot "${BUILD_ROOTFS}" /usr/bin/qemu-aarch64-static /bin/bash -c '
  # Enable Kore OS services
  systemctl enable kore-firstboot.service 2>/dev/null || true
  systemctl enable kore-welcome.service 2>/dev/null || true
  systemctl enable kore-bootsound.service 2>/dev/null || true

  # Enable SDDM (display manager)
  systemctl enable sddm.service 2>/dev/null || true

  # Enable networking
  systemctl enable NetworkManager.service 2>/dev/null || true
  systemctl enable systemd-resolved.service 2>/dev/null || true

  # Enable multimedia services
  systemctl enable pipewire.service 2>/dev/null || true
  systemctl enable wireplumber.service 2>/dev/null || true
  systemctl enable pipewire-pulse.service 2>/dev/null || true

  # Enable security services
  systemctl enable ufw.service 2>/dev/null || true

  # Set default Plymouth theme
  if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme kore 2>/dev/null || true
  fi

  # Create kore user for live session
  if ! id -u kore &>/dev/null 2>&1; then
    useradd -m -G sudo,audio,video,plugdev,storage,power,network \
      -s /bin/bash -c "Kore OS Live User" kore
    echo "kore:kore" | chpasswd 2>/dev/null || true
  fi

  # Copy skel to home
  if [ -d /etc/skel ]; then
    cp -r /etc/skel/. /home/kore/ 2>/dev/null || true
    chown -R kore:kore /home/kore/ 2>/dev/null || true
  fi

  # Sudoers for live session
  echo "kore ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kore-live

  # Disable SSH in live
  systemctl disable ssh.service 2>/dev/null || true
  systemctl disable sshd.service 2>/dev/null || true

  # SDDM autologin
  mkdir -p /etc/sddm.conf.d
  cat > /etc/sddm.conf.d/kore-autologin.conf << EOF
[Autologin]
Session=plasma
User=kore
Relogin=false
EOF
' 2>/dev/null || true

# ================================================================
# Phase 2: Apply branding, configs, overlay
# ================================================================
echo "[Kore OS Builder] Applying branding and configuration..."

sudo cp -r "${WORK_DIR}/configs/system/"* "${BUILD_ROOTFS}/etc/" 2>/dev/null || true
sudo rsync -a "${WORK_DIR}/overlay/airootfs/" "${BUILD_ROOTFS}/" 2>/dev/null || true

sudo mkdir -p "${BUILD_ROOTFS}/usr/share/backgrounds/kore"
sudo cp "${WORK_DIR}/assets/korebackground.png" \
  "${BUILD_ROOTFS}/usr/share/backgrounds/kore/korebackground.png"

sudo mkdir -p "${BUILD_ROOTFS}/usr/share/color-schemes"
sudo cp "${WORK_DIR}/configs/kde/colors/"*.colors \
  "${BUILD_ROOTFS}/usr/share/color-schemes/" 2>/dev/null || true

sudo mkdir -p "${BUILD_ROOTFS}/usr/share/plasma/look-and-feel/org.kore.plasma.desktop"
sudo cp -r "${WORK_DIR}/configs/kde/look-and-feel/org.kore.plasma.desktop/"* \
  "${BUILD_ROOTFS}/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/"

sudo mkdir -p "${BUILD_ROOTFS}/usr/share/sddm/themes/kore"
sudo cp -r "${WORK_DIR}/configs/kde/sddm/kore/"* \
  "${BUILD_ROOTFS}/usr/share/sddm/themes/kore/"

convert "${WORK_DIR}/assets/kore.png" -resize 256x256 /tmp/kore-logo-256.png 2>/dev/null || true
sudo mkdir -p "${BUILD_ROOTFS}/usr/share/plymouth/themes/kore"
sudo cp /tmp/kore-logo-256.png \
  "${BUILD_ROOTFS}/usr/share/plymouth/themes/kore/logo.png" 2>/dev/null || true
sudo mkdir -p "${BUILD_ROOTFS}/usr/share/sddm/themes/kore"
sudo cp /tmp/kore-logo-256.png \
  "${BUILD_ROOTFS}/usr/share/sddm/themes/kore/logo.png" 2>/dev/null || true
sudo mkdir -p \
  "${BUILD_ROOTFS}/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/contents/splash/images"
sudo cp /tmp/kore-logo-256.png \
  "${BUILD_ROOTFS}/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/contents/splash/images/kore-logo.png" 2>/dev/null || true
rm -f /tmp/kore-logo-256.png

sudo mkdir -p "${BUILD_ROOTFS}/etc/calamares"
sudo cp -r "${WORK_DIR}/configs/calamares/"* "${BUILD_ROOTFS}/etc/calamares/" 2>/dev/null || true

sudo mkdir -p "${BUILD_ROOTFS}/usr/local/bin"
sudo cp "${WORK_DIR}/scripts/kore-firstboot.sh" "${BUILD_ROOTFS}/usr/local/bin/" 2>/dev/null || true
sudo cp "${WORK_DIR}/scripts/kore-welcome" "${BUILD_ROOTFS}/usr/local/bin/" 2>/dev/null || true

echo "[Kore OS Builder] Configuring initramfs..."
sudo tee "${BUILD_ROOTFS}/etc/initramfs-tools/modules" >/dev/null << 'INITRD_MODULES'
virtio_blk
virtio_pci
virtio
virtio_ring
virtio_mmio
virtio_net
nvme
INITRD_MODULES

sudo tee "${BUILD_ROOTFS}/etc/initramfs-tools/initramfs.conf" >/dev/null << 'INITRD_CONF'
MODULES=most
BUSYBOX=auto
COMPRESS=zstd
INITRD_CONF

# Generate initramfs
echo "[Kore OS Builder] Generating initramfs..."
KERNEL_VER=$(sudo ls "${BUILD_ROOTFS}/lib/modules/" 2>/dev/null | sort -V | tail -1 || echo "")
if [ -n "${KERNEL_VER}" ]; then
  echo "[Kore OS Builder] Detected kernel: ${KERNEL_VER}"
  sudo DEBIAN_FRONTEND=noninteractive chroot "${BUILD_ROOTFS}" /usr/bin/qemu-aarch64-static /bin/bash -c "
    mkinitramfs -o /boot/initramfs-linux.img '${KERNEL_VER}' 2>&1
  " || echo "[WARN] initramfs generation failed"
  sudo ls -la "${BUILD_ROOTFS}/boot/" 2>/dev/null || true
fi

# Create GRUB config
echo "[Kore OS Builder] Creating GRUB config..."
sudo mkdir -p "${BUILD_ROOTFS}/boot/grub"

KERNEL_NAME=""
for f in "${BUILD_ROOTFS}/boot/vmlinuz-"*; do
  if [ -f "$f" ]; then
    KERNEL_NAME=$(basename "$f")
    break
  fi
done
KERNEL_NAME="${KERNEL_NAME:-vmlinuz-linux-arm64}"

sudo tee "${BUILD_ROOTFS}/boot/grub/grub.cfg" >/dev/null << GRUB_CFG
set default="0"
set timeout=5
set gfxpayload=keep
insmod efi_gop
insmod efi_uga
insmod video_bochs
insmod video_cirrus
insmod all_video
insmod part_gpt
insmod ext2
insmod fat
insmod gzio
loadfont unicode
set gfxmode=1920x1080,1280x720,auto
terminal_output gfxterm
menuentry "Kore OS" {
  linux /boot/${KERNEL_NAME} root=/dev/vda2 rw rootwait console=ttyAMA0,115200 earlycon apparmor=1 security=apparmor audit=1
  initrd /boot/initramfs-linux.img
}
menuentry "Kore OS (Safe Mode)" {
  linux /boot/${KERNEL_NAME} root=/dev/vda2 rw rootwait console=ttyAMA0,115200 nomodeset
  initrd /boot/initramfs-linux.img
}
menuentry "Reboot" { reboot }
menuentry "Shutdown" { halt }
GRUB_CFG

# Save kernel and bootloader info for later
sudo cp "${BUILD_ROOTFS}/boot/grub/grub.cfg" /tmp/koreos-grub.cfg 2>/dev/null || true
sudo cp "${BUILD_ROOTFS}/boot/${KERNEL_NAME}" /tmp/koreos-kernel-image 2>/dev/null || true

# ================================================================
# Phase 3: Unmount chroot and create disk image
# ================================================================
echo "[Kore OS Builder] Unmounting chroot..."
chroot_umount
trap - EXIT

echo "[Kore OS Builder] Creating disk image..."
dd if=/dev/zero of="${IMG_FILE}" bs=1M count=0 seek=${TOTAL_MB}
sudo parted -s "${IMG_FILE}" mklabel gpt
sudo parted -s "${IMG_FILE}" mkpart ESP fat32 1MiB "${ESP_SIZE_MB}MiB"
sudo parted -s "${IMG_FILE}" set 1 esp on
sudo parted -s "${IMG_FILE}" mkpart root ext4 "${ROOT_START_MB}MiB" "${ROOT_END_MB}MiB"

echo "[Kore OS Builder] Formatting ESP..."
dd if=/dev/zero of="${TMP_ESP}" bs=1M count=${ESP_SIZE_MB} status=progress
sudo mkfs.vfat -F32 "${TMP_ESP}"
dd if="${TMP_ESP}" of="${IMG_FILE}" bs=512 seek=$((ESP_OFFSET / 512)) conv=notrunc status=progress
rm -f "${TMP_ESP}"

echo "[Kore OS Builder] Formatting root partition..."
sudo mkfs.ext4 -F -E offset=${ROOT_OFFSET} "${IMG_FILE}" ${ROOT_SIZE_KB}

echo "[Kore OS Builder] Writing rootfs to image..."
sudo mount -o loop,offset=${ROOT_OFFSET},sizelimit=${ROOT_SIZE_BYTES} "${IMG_FILE}" "${IMAGE_MNT}"
sudo rsync -a "${BUILD_ROOTFS}/" "${IMAGE_MNT}/" \
  --exclude='proc' --exclude='sys' --exclude='dev' --exclude='mnt' --exclude='tmp'
sync
sudo umount "${IMAGE_MNT}"

echo "[Kore OS Builder] Setting up ESP..."
sudo mount -o loop,offset=${ESP_OFFSET},sizelimit=${ESP_SIZE_BYTES} "${IMG_FILE}" "${ESP_DIR}"
sudo mkdir -p "${ESP_DIR}/EFI/BOOT"

KERNEL_IMG=""
for f in "${BUILD_ROOTFS}/boot/vmlinuz-"*; do
  if [ -f "$f" ]; then KERNEL_IMG="$f"; break; fi
done
if [ -z "${KERNEL_IMG}" ] && [ -f /tmp/koreos-kernel-image ]; then
  KERNEL_IMG="/tmp/koreos-kernel-image"
fi
if [ -n "${KERNEL_IMG}" ]; then
  echo "[Kore OS Builder] Kernel: ${KERNEL_IMG}"
  sudo cp "${KERNEL_IMG}" "${ESP_DIR}/EFI/BOOT/Image"
fi
if [ -f "${BUILD_ROOTFS}/boot/initramfs-linux.img" ]; then
  sudo cp "${BUILD_ROOTFS}/boot/initramfs-linux.img" "${ESP_DIR}/EFI/BOOT/"
fi

GRUB_EFI="${BUILD_ROOTFS}/usr/lib/grub/arm64-efi/grub.efi"
if [ -f "${GRUB_EFI}" ]; then
  echo "[Kore OS Builder] Installing GRUB EFI..."
  sudo cp "${GRUB_EFI}" "${ESP_DIR}/EFI/BOOT/BOOTAA64.EFI"
elif [ -f "${BUILD_ROOTFS}/usr/lib/systemd/boot/efi/systemd-bootaa64.efi" ]; then
  echo "[Kore OS Builder] Installing systemd-boot..."
  sudo cp "${BUILD_ROOTFS}/usr/lib/systemd/boot/efi/systemd-bootaa64.efi" \
    "${ESP_DIR}/EFI/BOOT/BOOTAA64.EFI"
  sudo mkdir -p "${ESP_DIR}/loader/entries"
  echo -e "default kore\ntimeout 5\nconsole-mode max" | sudo tee "${ESP_DIR}/loader/loader.conf" >/dev/null
  INIRD=""
  [ -f "${ESP_DIR}/EFI/BOOT/initramfs-linux.img" ] && INIRD="initrd /EFI/BOOT/initramfs-linux.img"
  sudo tee "${ESP_DIR}/loader/entries/kore.conf" >/dev/null << ENTRY
title   Kore OS
linux   /EFI/BOOT/Image
${INIRD}
options root=/dev/vda2 rw rootwait console=ttyAMA0,115200 earlycon apparmor=1 security=apparmor audit=1
ENTRY
else
  echo "[Kore OS Builder] Trying grub-mkstandalone..."
  if command -v grub-mkstandalone &>/dev/null && [ -f /tmp/koreos-grub.cfg ]; then
    sudo grub-mkstandalone -O arm64-efi \
      -o "${ESP_DIR}/EFI/BOOT/BOOTAA64.EFI" \
      --modules="part_gpt part_msdos ext2 fat gzio efi_gop efi_uga video" \
      "boot/grub/grub.cfg=/tmp/koreos-grub.cfg" 2>&1 || true
  fi
fi

sync
sudo umount "${ESP_DIR}" 2>/dev/null || true

sudo rm -rf "${BUILD_ROOTFS}" "${ESP_DIR}" "${IMAGE_MNT}" \
  /tmp/koreos-grub.cfg /tmp/koreos-kernel-image 2>/dev/null || true

echo "[Kore OS Builder] Compressing image..."
xz -9 -f "${IMG_FILE}"

echo "[Kore OS Builder] Done!"
echo "Image available at: ${IMG_FILE}.xz"
ls -lh "${IMG_FILE}.xz"
