#!/bin/sh
# Copyright (c) 2026 ljc
# SPDX-License-Identifier: MIT
# Install the MT7902 Bluetooth (btmtk) DKMS module.
# Usage: sudo ./install.sh [--reload]
#   --reload  stop bluetooth, reload btusb/btmtk so the new module is used now
#             (otherwise it takes effect after the next reboot)
set -eu

NAME=btmtk-mt7902
VER=1.0
SRC=/usr/src/$NAME-$VER
HERE=$(cd "$(dirname "$0")" && pwd)
RELOAD=0
[ "${1:-}" = "--reload" ] && RELOAD=1

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root: sudo $0"
KVER=$(uname -r)
case "$KVER" in
	6.17.*) ;;
	*) die "kernel $KVER is not 6.17.x. Kernels >= 7.1 already support MT7902 Bluetooth;" \
	       "other series are untested (the bundled btmtk.c is based on v6.17)." ;;
esac
command -v dkms >/dev/null 2>&1 || die "dkms not found (Debian/Ubuntu: apt install dkms)"
[ -f "/lib/modules/$KVER/build/Makefile" ] || die "kernel headers missing (apt install linux-headers-$KVER)"

# Warn (do not fail) if no MT7902 Bluetooth device is present.
if command -v lsusb >/dev/null 2>&1 && ! lsusb | grep -qi '0e8d:7902'; then
	echo "NOTE: no USB device 0e8d:7902 found; installing anyway."
fi
[ -f /lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin ] || \
	echo "WARNING: /lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin is missing;" \
	     "install linux-firmware (newer) or the file from linux-firmware.git first."

# Remove a previous copy of the same version.
if dkms status -m "$NAME" -v "$VER" 2>/dev/null | grep -q "$NAME"; then
	dkms remove -m "$NAME" -v "$VER" --all >/dev/null 2>&1 || true
fi
rm -rf "$SRC"
mkdir -p "$SRC"
cp -r "$HERE/dkms.conf" "$HERE/Makefile" "$HERE/src" "$SRC/"

dkms add -m "$NAME" -v "$VER"
dkms build -m "$NAME" -v "$VER" -k "$KVER"
dkms install -m "$NAME" -v "$VER" -k "$KVER" --force
depmod -a "$KVER"

echo "Installed: $(modinfo -n btmtk)"

if [ "$RELOAD" -eq 1 ]; then
	systemctl stop bluetooth 2>/dev/null || true
	modprobe -r btusb 2>/dev/null || true
	modprobe -r btmtk 2>/dev/null || true
	modprobe btusb
	sleep 5
	systemctl start bluetooth 2>/dev/null || true
	echo "Reloaded. Check: hciconfig -a   (BD Address must not be 00:00:00:00:00:00)"
else
	echo "Reboot (or re-run with --reload) to activate."
fi
