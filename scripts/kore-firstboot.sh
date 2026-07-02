#!/bin/bash
#
# Kore OS - First Boot Setup Script
# Runs once on initial boot to configure the system
#

set -euo pipefail

FIRST_BOOT_FLAG="/var/lib/kore-firstboot-done"

if [ -f "${FIRST_BOOT_FLAG}" ]; then
    exit 0
fi

# Create kore user for SDDM auto-login
if ! id -u kore &>/dev/null 2>&1; then
    useradd -m -G sudo,audio,video,plugdev,storage,power,network \
        -s /bin/bash -c "Kore OS Live User" kore
    echo "kore:kore" | chpasswd &>/dev/null 2>&1 || true
fi

# Set up user directories
if [ -d /etc/skel ]; then
    cp -r /etc/skel/. /home/kore/ 2>/dev/null || true
    chown -R kore:kore /home/kore/ 2>/dev/null || true
fi

# Configure default wallpaper for kore user
sudo -u kore bash -c '
if command -v kwriteconfig5 &>/dev/null 2>&1; then
    kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
        --group Containments \
        --group 1 \
        --group Wallpaper \
        --group org.kde.image \
        --group General \
        --key Image "file:///usr/share/backgrounds/kore/korebackground.png" 2>/dev/null || true
fi
' 2>/dev/null || true

# Enable KDE Plasma Kore theme
if command -v lookandfeeltool &>/dev/null 2>&1; then
    sudo -u kore lookandfeeltool -a "org.kore.plasma.desktop" 2>/dev/null || true
fi

# Ensure firewall is active
if command -v ufw &>/dev/null 2>&1; then
    ufw --force enable 2>/dev/null || true
fi

# Mark first boot as complete
touch "${FIRST_BOOT_FLAG}"

echo "Kore OS first-time setup complete."
exit 0
