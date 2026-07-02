#!/bin/bash
#
# Kore OS automated setup script
# Runs on live environment start
#

set -euo pipefail

echo "Initializing Kore OS live environment..."

# Set up XDG directories
export XDG_CONFIG_HOME=/home/kore/.config
export XDG_DATA_HOME=/home/kore/.local/share

# Start SDDM
if systemctl is-enabled sddm &>/dev/null 2>&1; then
    systemctl start sddm
fi

echo "Kore OS live environment ready."
