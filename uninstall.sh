#!/bin/bash
# Uninstall Voron TAP auto_tap Klipper extra (reverse of install.sh)
#
# Copyright (C) 2023-2025 Anonoei / forked by user
# This file may be distributed under the terms of the MIT license.
#
# Usage: run as non-root user. The script will use sudo where necessary.

set -e

KLIPPER_PATH="${HOME}/klipper"
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"
TARGET="${KLIPPER_PATH}/klippy/extras/auto_tap.py"

# Do not run as root (same behavior as install.sh)
if [ "$(id -u)" -eq 0 ]; then
    echo "This script must not run as root"
    exit 1
fi

echo "Uninstalling auto_tap from Klipper..."

# Verify klipper path exists
if [ ! -d "${KLIPPER_PATH}" ]; then
    echo "Klipper path not found at ${KLIPPER_PATH}. Nothing to uninstall."
    exit 0
fi

# Remove the installed module
if [ -L "${TARGET}" ]; then
    LINK_TARGET="$(readlink "${TARGET}" 2>/dev/null || true)"
    rm -f "${TARGET}"
    echo "Removed symlink: ${TARGET} -> ${LINK_TARGET}"
elif [ -e "${TARGET}" ]; then
    echo "Found non-symlink file at ${TARGET}. Not removing automatically for safety."
    echo "If you intend to remove it, run: sudo rm -f \"${TARGET}\""
else
    echo "No auto_tap.py found at ${TARGET}."
fi

# Remove compiled bytecode for this module (non-fatal)
CACHE_DIR="${KLIPPER_PATH}/klippy/extras/__pycache__"
if [ -d "${CACHE_DIR}" ]; then
    echo "Cleaning compiled bytecode in ${CACHE_DIR}..."
    find "${CACHE_DIR}" -maxdepth 1 -type f -name 'auto_tap.*.pyc' -print -delete || true
fi

# Also try to find any stray compiled files elsewhere in klippy/extras (best-effort)
echo "Searching for stray compiled files..."
find "${KLIPPER_PATH}/klippy/extras" -type f -name 'auto_tap.*.py[co]' -print -delete >/dev/null 2>&1 || true

# Restart Klipper if the service is present
if sudo systemctl list-units --full -all -t service --no-legend | grep -Fq "klipper.service"; then
    echo "Restarting Klipper..."
    if sudo systemctl restart klipper; then
        echo "Klipper restarted."
    else
        echo "Warning: Failed to restart Klipper."
        echo "If your printer.cfg still references sections that depend on auto_tap, remove them and restart Klipper manually:"
        echo "  sudo systemctl restart klipper"
    fi
else
    echo "Klipper service not found; skipping restart."
fi

echo "Uninstall complete."
exit 0
