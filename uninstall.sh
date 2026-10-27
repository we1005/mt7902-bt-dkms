#!/bin/sh
# Copyright (c) 2026 ljc
# SPDX-License-Identifier: MIT
# Remove the MT7902 Bluetooth (btmtk) DKMS module and restore the in-kernel one.
# Usage: sudo ./uninstall.sh
set -eu
NAME=btmtk-mt7902
VER=1.0
[ "$(id -u)" -eq 0 ] || { echo "run as root: sudo $0" >&2; exit 1; }

dkms remove -m "$NAME" -v "$VER" --all 2>/dev/null || true
rm -rf "/usr/src/$NAME-$VER"
depmod -a "$(uname -r)"

systemctl stop bluetooth 2>/dev/null || true
modprobe -r btusb 2>/dev/null || true
modprobe -r btmtk 2>/dev/null || true
modprobe btusb || true
systemctl start bluetooth 2>/dev/null || true
echo "Removed. btmtk is now: $(modinfo -n btmtk)"
