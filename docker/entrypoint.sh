#!/bin/bash
set -euo pipefail

export BUILD_MODE="${BUILD_MODE:-iso}"
export ARCH="${ARCH:-x86_64}"
export KORE_VERSION="${KORE_VERSION:-1.0.0}"
export BUILD_DATE="$(date -u +%Y%m%d)"

echo "========================================"
echo "  Kore OS Build System"
echo "  Version: ${KORE_VERSION}"
echo "  Date:    ${BUILD_DATE}"
echo "  Mode:    ${BUILD_MODE}"
echo "  Arch:    ${ARCH}"
echo "========================================"
echo ""

bootstrap() {
    echo "[Bootstrap] Installing build tools..."

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        live-build \
        xorriso \
        debootstrap \
        qemu-user-static \
        parted \
        dosfstools \
        e2fsprogs \
        squashfs-tools \
        xz-utils \
        imagemagick \
        rsync \
        wget \
        mtools \
        jq \
        git \
        grub-pc-bin \
        grub-efi-amd64-bin \
        grub-efi-ia32-bin \
        systemd \
        systemd-resolved \
        udev \
        2>&1 | tail -5

    sudo apt-get clean
    rm -rf /tmp/* 2>/dev/null || true

    echo "[Bootstrap] Build environment ready."
    echo ""
}

bootstrap

case "${BUILD_MODE}" in
  iso|x86_64)
    echo "Building Kore OS x86_64 ISO..."
    exec /opt/koreos/scripts/build-x86_64.sh
    ;;
  aarch64)
    echo "Building Kore OS aarch64 image..."
    exec /opt/koreos/scripts/build-aarch64.sh
    ;;
  shell)
    echo "Starting interactive shell..."
    exec /bin/bash
    ;;
  *)
    echo "Unknown build mode: ${BUILD_MODE}"
    echo "Valid modes: iso, aarch64, shell"
    exit 1
    ;;
esac
