#!/bin/bash
# Fix 8BitDo SN30 Pro controller dropout caused by parent USB hub autosuspend
#
# The Realtek USB hub (0bda:5411) at bus 1-9 has autosuspend enabled,
# which can cause the xpad driver to hit USB URB failures and lose
# communication with the controller.
#
# This script:
# 1. Disables autosuspend on the hub immediately
# 2. Installs a udev rule so the fix persists across reboots

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# Immediate fix
HUB_POWER="/sys/bus/usb/devices/1-9/power/control"
if [ -f "$HUB_POWER" ]; then
    echo "on" > "$HUB_POWER"
    echo "Disabled autosuspend on USB hub (1-9): $(cat "$HUB_POWER")"
else
    echo "Warning: $HUB_POWER not found. Hub may be on a different port."
fi

# Persistent udev rule
RULES_FILE="/etc/udev/rules.d/50-usb-hub-no-autosuspend.rules"
cat > "$RULES_FILE" <<'EOF'
# Disable autosuspend on Realtek USB hub to prevent 8BitDo controller dropout
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="5411", ATTR{power/control}="on"
EOF

udevadm control --reload-rules
echo "Installed udev rule at $RULES_FILE"
echo "Done. Play-test to see if the controller stays connected."
