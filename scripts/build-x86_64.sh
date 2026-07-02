#!/bin/bash
set -euo pipefail

echo "[Kore OS Builder] Setting up x86_64 ISO build environment..."

KORE_VERSION="${KORE_VERSION:-1.0.0}"
BUILD_DATE="${BUILD_DATE:-$(date -u +%Y%m%d)}"
WORK_DIR="/opt/koreos"
OUTPUT_DIR="${WORK_DIR}/output"
BUILD_DIR="/tmp/koreos-live-build"
ISO_NAME="koreos-${KORE_VERSION}-x86_64"

mkdir -p "${OUTPUT_DIR}" "${BUILD_DIR}"

# Clean any previous build
rm -rf "${BUILD_DIR:?}"/*
cd "${BUILD_DIR}"

echo "[Kore OS Builder] Configuring live-build..."

lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootappend-live "quiet splash loglevel=3 apparmor=1 security=apparmor audit=1" \
  --debian-installer false \
  --linux-flavours amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --iso-volume "KOREOS" \
  --iso-publisher "Kore OS <https://wsgpolar.me>" \
  --iso-application "Kore OS Live/Rescue System" \
  --memtest none \
  --parent-distribution trixie \
  --parent-archive-areas "main contrib non-free-firmware" \
  --security true \
  --updates true \
  --backports true \
  --utc-time true \
  --source false \
  --system live

echo "[Kore OS Builder] Writing package list..."

mkdir -p config/package-lists

cat > config/package-lists/kore-desktop.list.chroot << 'PKGLIST'
# Kore OS - KDE Plasma Desktop Package Set (Debian 13 Trixie)

# === KERNEL ===
linux-image-amd64
linux-headers-amd64
firmware-linux
firmware-linux-nonfree
firmware-amd-graphics

# === KERNEL MODULES (for VMs) ===
spice-vdagent
qemu-guest-agent

# === BOOT & INIT ===
grub-efi-amd64
grub-efi-ia32-bin
efibootmgr
plymouth
plymouth-themes
systemd
systemd-sysv
initramfs-tools

# === DISPLAY SERVER ===
xserver-xorg-core
xserver-xorg-video-all
xserver-xorg-input-all
mesa-utils
libgl1-mesa-dri
libgl1
mesa-vulkan-drivers
va-driver-all

# === KDE PLASMA ===
kde-plasma-desktop
plasma-nm
plasma-pa
kde-config-gtk-style
kde-config-gtk-style-preview
kde-config-sddm
kwin-x11
kwin-wayland
sddm
sddm-theme-breeze
powerdevil
systemsettings
kinfocenter
plasma-widgets-addons
plasma-systemmonitor
kactivitymanagerd
polkit-kde-agent-1

# === KDE APPLICATIONS ===
dolphin
konsole
kate
gwenview
kde-spectacle
ark
kcalc
okular
kwrite
kfind
kgpg
print-manager

# === NETWORKING ===
network-manager
plasma-nm
wpasupplicant
openssh-server
curl
wget

# === AUDIO ===
pipewire
pipewire-pulse
pipewire-alsa
wireplumber
firmware-sof-signed

# === SECURITY ===
ufw
apparmor
apparmor-profiles
apparmor-utils
fail2ban
auditd
lynis

# === FILESYSTEMS ===
btrfs-progs
dosfstools
e2fsprogs
exfatprogs
ntfs-3g
xfsprogs
squashfs-tools
lvm2
cryptsetup
udisks2

# === UTILITIES ===
sudo
nano
htop
fastfetch
pciutils
usbutils
unzip
unrar-free
p7zip
zip
rsync
bash-completion
man-db
manpages
xdg-user-dirs
xdg-utils
dbus-x11

# === FONTS ===
fonts-noto
fonts-noto-color-emoji
fonts-dejavu
fonts-liberation
fonts-jetbrains-mono

# === THEMING ===
qt-style-kvantum
qt5ct
qt6ct
breeze
breeze-gtk-theme
breeze-icon-theme

# === FIRMWARE ===
amd64-microcode

# === CALAMARES INSTALLER ===
calamares

# === PRINTING ===
cups
printer-driver-cups-pdf
hplip
# === BLUETOOTH ===
bluez
bluez-obexd

# === PLYMOUTH ===
plymouth-label
PKGLIST

echo "[Kore OS Builder] Setting up filesystem overlay..."
mkdir -p config/includes.chroot

# Copy overlay files into the live system
if [ -d "${WORK_DIR}/overlay/airootfs" ]; then
  rsync -a "${WORK_DIR}/overlay/airootfs/" config/includes.chroot/
fi

# Copy branding assets
mkdir -p config/includes.chroot/usr/share/backgrounds/kore
cp "${WORK_DIR}/assets/korebackground.png" \
  config/includes.chroot/usr/share/backgrounds/kore/korebackground.png

echo "[Kore OS Builder] Copying system configurations..."
mkdir -p config/includes.chroot/etc
if [ -d "${WORK_DIR}/configs/system" ]; then
  rsync -a "${WORK_DIR}/configs/system/" config/includes.chroot/etc/
fi

echo "[Kore OS Builder] Copying KDE Plasma look-and-feel..."
mkdir -p config/includes.chroot/usr/share/plasma/look-and-feel/org.kore.plasma.desktop
if [ -d "${WORK_DIR}/configs/kde/look-and-feel/org.kore.plasma.desktop" ]; then
  cp -r "${WORK_DIR}/configs/kde/look-and-feel/org.kore.plasma.desktop/"* \
    config/includes.chroot/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/
fi

echo "[Kore OS Builder] Copying SDDM theme..."
mkdir -p config/includes.chroot/usr/share/sddm/themes/kore
if [ -d "${WORK_DIR}/configs/kde/sddm/kore" ]; then
  cp -r "${WORK_DIR}/configs/kde/sddm/kore/"* \
    config/includes.chroot/usr/share/sddm/themes/kore/
fi

echo "[Kore OS Builder] Copying color schemes..."
mkdir -p config/includes.chroot/usr/share/color-schemes
if [ -d "${WORK_DIR}/configs/kde/colors" ]; then
  cp "${WORK_DIR}/configs/kde/colors/"*.colors \
    config/includes.chroot/usr/share/color-schemes/ 2>/dev/null || true
fi

echo "[Kore OS Builder] Setting up Plymouth theme..."
mkdir -p config/includes.chroot/usr/share/plymouth/themes/kore
if [ -d "${WORK_DIR}/configs/boot/plymouth/kore" ]; then
  cp "${WORK_DIR}/configs/boot/plymouth/kore/"* \
    config/includes.chroot/usr/share/plymouth/themes/kore/ 2>/dev/null || true
fi
convert "${WORK_DIR}/assets/kore.png" -resize 256x256 \
  config/includes.chroot/usr/share/plymouth/themes/kore/logo.png 2>/dev/null || true

echo "[Kore OS Builder] Setting up GRUB theme..."
mkdir -p config/includes.chroot/usr/share/grub/themes/kore/icons
if [ -d "${WORK_DIR}/configs/boot/grub" ]; then
  cp -r "${WORK_DIR}/configs/boot/grub/"* \
    config/includes.chroot/usr/share/grub/themes/kore/ 2>/dev/null || true
fi
convert "${WORK_DIR}/assets/kore.png" -resize 256x256 \
  config/includes.chroot/usr/share/grub/themes/kore/icons/kore.png 2>/dev/null || true

echo "[Kore OS Builder] Generating GRUB splash from wallpaper..."
convert "${WORK_DIR}/assets/korebackground.png" -resize 1920x1080^ -gravity center -extent 1920x1080 \
  -blur 0x8 -fill black -colorize 60% \
  config/includes.chroot/usr/share/grub/themes/kore/splash.png 2>/dev/null || true

echo "[Kore OS Builder] Generating Plymouth logo..."
convert "${WORK_DIR}/assets/kore.png" -resize 512x512 \
  config/includes.chroot/usr/share/plymouth/themes/kore/logo.png 2>/dev/null || true

echo "[Kore OS Builder] Creating splash logo for KDE..."
mkdir -p config/includes.chroot/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/contents/splash/images
convert "${WORK_DIR}/assets/kore.png" -resize 256x256 \
  config/includes.chroot/usr/share/plasma/look-and-feel/org.kore.plasma.desktop/contents/splash/images/kore-logo.png 2>/dev/null || true

echo "[Kore OS Builder] Copying SDDM logo..."
mkdir -p config/includes.chroot/usr/share/sddm/themes/kore
cp config/includes.chroot/usr/share/plymouth/themes/kore/logo.png \
  config/includes.chroot/usr/share/sddm/themes/kore/logo.png 2>/dev/null || true

echo "[Kore OS Builder] Copying Calamares configuration..."
mkdir -p config/includes.chroot/etc/calamares
if [ -d "${WORK_DIR}/configs/calamares" ]; then
  cp -r "${WORK_DIR}/configs/calamares/"* config/includes.chroot/etc/calamares/
fi

echo "[Kore OS Builder] Copying scripts..."
mkdir -p config/includes.chroot/usr/local/bin
cp "${WORK_DIR}/scripts/kore-firstboot.sh" config/includes.chroot/usr/local/bin/ 2>/dev/null || true
cp "${WORK_DIR}/scripts/kore-welcome" config/includes.chroot/usr/local/bin/ 2>/dev/null || true

echo "[Kore OS Builder] Copying Kvantum and sound themes..."
if [ -d "${WORK_DIR}/overlay/airootfs/usr/share/Kvantum" ]; then
  mkdir -p config/includes.chroot/usr/share/Kvantum
  cp -r "${WORK_DIR}/overlay/airootfs/usr/share/Kvantum/"* \
    config/includes.chroot/usr/share/Kvantum/
fi
if [ -d "${WORK_DIR}/overlay/airootfs/usr/share/sounds" ]; then
  mkdir -p config/includes.chroot/usr/share/sounds
  cp -r "${WORK_DIR}/overlay/airootfs/usr/share/sounds/"* \
    config/includes.chroot/usr/share/sounds/ 2>/dev/null || true
fi

echo "[Kore OS Builder] Setting up initramfs-tools for virtio..."
mkdir -p config/includes.chroot/etc/initramfs-tools
cat > config/includes.chroot/etc/initramfs-tools/modules << 'INITRD_MODULES'
# VirtIO modules for QEMU/KVM/UTM
virtio_blk
virtio_pci
virtio
virtio_ring
virtio_mmio
virtio_net
nvme
ahci
INITRD_MODULES

# Create a initramfs-tools conf to set MODULES=most
cat > config/includes.chroot/etc/initramfs-tools/initramfs.conf << 'INITRD_CONF'
#
# Kore OS initramfs-tools configuration
#
MODULES=most
BUSYBOX=auto
COMPRESS=zstd
INITRD_CONF

echo "[Kore OS Builder] Creating first-boot hook..."
mkdir -p config/hooks/live

cat > config/hooks/live/9901-kore-firstboot.hook.chroot << 'HOOK_CHROOT'
#!/bin/bash
# Enable kore-firstboot.service
if [ -f /usr/lib/systemd/system/kore-firstboot.service ]; then
  systemctl enable kore-firstboot.service 2>/dev/null || true
fi
if [ -f /usr/lib/systemd/system/kore-welcome.service ]; then
  systemctl enable kore-welcome.service 2>/dev/null || true
fi
if [ -f /usr/lib/systemd/system/kore-bootsound.service ]; then
  systemctl enable kore-bootsound.service 2>/dev/null || true
fi

# Enable SDDM
systemctl enable sddm.service 2>/dev/null || true

# Enable NetworkManager
systemctl enable NetworkManager.service 2>/dev/null || true

# Enable systemd-resolved
systemctl enable systemd-resolved.service 2>/dev/null || true

# Enable multimedia services
systemctl enable pipewire.service 2>/dev/null || true
systemctl enable wireplumber.service 2>/dev/null || true
systemctl enable pipewire-pulse.service 2>/dev/null || true

# Enable security services
systemctl enable ufw.service 2>/dev/null || true

# Set default Plymouth theme to kore
if command -v plymouth-set-default-theme &>/dev/null; then
  plymouth-set-default-theme kore 2>/dev/null || true
fi

# Create kore user for live session
if ! id -u kore &>/dev/null 2>&1; then
  useradd -m -G sudo,audio,video,plugdev,storage,power,network \
    -s /bin/bash -c "Kore OS Live User" kore
  echo "kore:kore" | chpasswd 2>/dev/null || true
fi

# Set up default user directories
if [ -d /etc/skel ]; then
  cp -r /etc/skel/. /home/kore/ 2>/dev/null || true
  chown -R kore:kore /home/kore/ 2>/dev/null || true
fi

# Make sure kore can sudo without password for live session
echo "kore ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kore-live

# Disable SSH by default in live (security)
systemctl disable ssh.service 2>/dev/null || true
systemctl disable sshd.service 2>/dev/null || true

# Clean up apt cache
apt-get clean 2>/dev/null || true

# Configure default GRUB settings for installed system
if [ -f /etc/default/grub ]; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash apparmor=1 security=apparmor audit=1"/' /etc/default/grub 2>/dev/null || true
fi
HOOK_CHROOT
chmod +x config/hooks/live/9901-kore-firstboot.hook.chroot

cat > config/hooks/live/9902-kore-cleanup.hook.chroot << 'CLEANUP'
#!/bin/bash
# Clean up machine-id
rm -f /etc/machine-id 2>/dev/null || true
rm -f /var/lib/dbus/machine-id 2>/dev/null || true
CLEANUP
chmod +x config/hooks/live/9902-kore-cleanup.hook.chroot

echo "[Kore OS Builder] Setting up KDE autologin for kore user in live session..."
mkdir -p config/includes.chroot/etc/sddm.conf.d
cat > config/includes.chroot/etc/sddm.conf.d/kore-autologin.conf << 'SDDM_CONF'
[Autologin]
Session=plasma
User=kore
Relogin=false
SDDM_CONF

echo "[Kore OS Builder] Setting up GRUB bootloader for live ISO..."
mkdir -p config/bootloaders

# live-build generates its own GRUB config - we'll override it
mkdir -p config/includes.binary/boot/grub/themes/kore/icons
cp config/includes.chroot/usr/share/grub/themes/kore/* \
  config/includes.binary/boot/grub/themes/kore/ 2>/dev/null || true

echo "[Kore OS Builder] Running live-build (this will take a while)..."
echo "[Kore OS Builder] Build started at: $(date -u)"

sudo lb build 2>&1 | tee "${OUTPUT_DIR}/live-build.log" || {
  rc=$?
  echo "[Kore OS Builder] ERROR: live-build failed with exit code ${rc}"
  echo "[Kore OS Builder] Check ${OUTPUT_DIR}/live-build.log for details"
  exit ${rc}
}

echo "[Kore OS Builder] Live-build complete at: $(date -u)"

# Find the built ISO
BUILT_ISO=$(ls -t live-image-amd64.hybrid.iso live-image-amd64.iso 2>/dev/null | head -1 || true)
if [ -z "${BUILT_ISO}" ]; then
  echo "[Kore OS Builder] ERROR: Could not find built ISO"
  ls -la "${BUILD_DIR}/" 2>/dev/null || true
  exit 1
fi

echo "[Kore OS Builder] Found ISO: ${BUILT_ISO}"

# Rename and copy to output
cp "${BUILT_ISO}" "${OUTPUT_DIR}/${ISO_NAME}.iso"
echo "[Kore OS Builder] ISO copied to ${OUTPUT_DIR}/${ISO_NAME}.iso"

# Show built ISO
ls -lh "${OUTPUT_DIR}/${ISO_NAME}.iso"

echo "[Kore OS Builder] Cleaning up build directory..."
sudo rm -rf "${BUILD_DIR:?}"/* 2>/dev/null || true

echo "[Kore OS Builder] Done!"
echo "ISO available at: ${OUTPUT_DIR}/${ISO_NAME}.iso"
