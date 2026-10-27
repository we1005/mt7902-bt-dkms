# Troubleshooting

Start with:

```sh
uname -r                       # must be 6.17.x
lsusb | grep -iE '0e8d|13d3|0489'
modinfo -n btmtk               # should end in updates/dkms/btmtk.ko.zst
dkms status                    # btmtk-mt7902/1.0, <kernel>: installed
hciconfig -a                   # BD Address must not be all zeros
sudo dmesg | grep -iE 'hci0|btmtk|btusb|firmware'
```

## `install.sh` says the kernel is not 6.17.x

Intentional. The bundled `btmtk.c` is the v6.17 version. On ≥ 7.1 the kernel already supports MT7902 Bluetooth; on 6.18–7.0 this package is untested.

## Still `Unsupported hardware variant (00007902)` after install

- `modinfo -n btmtk` shows `kernel/...` instead of `updates/dkms/...` → the patched module is not first in line. Run `sudo depmod -a`, then `sudo ./install.sh --reload` or reboot.
- The old module is still loaded. `lsmod | grep btmtk` + `sudo modprobe -r btusb btmtk && sudo modprobe btusb` (or `--reload`).
- Your device is not bound by `btusb` with the MediaTek flag on 6.17 (e.g. `13d3:35xx`, `0489:e156`). See *Which MT7902 Bluetooth devices does this help?* in the README. A `btusb` patch would be needed.

## `Direct firmware load for mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin failed with error -2`

The firmware file is missing. Ubuntu 24.04's `linux-firmware` (20240318) predates it. Download `BT_RAM_CODE_MT7902_1_1_hdr.bin` from [linux-firmware.git](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/mediatek) into `/lib/firmware/mediatek/`, then `sudo ./install.sh --reload` (or `sudo modprobe -r btusb btmtk && sudo modprobe btusb`). If you run initramfs-embedded firmware, also run `sudo update-initramfs -u`.

## `hci0` is up but `bluetoothctl` shows no controller

`sudo systemctl restart bluetooth`; `rfkill list bluetooth` must show no blocks; `sudo rfkill unblock bluetooth`.

## Module does not load with Secure Boot enabled

Expected for unsigned out-of-tree modules unless the DKMS signing key is enrolled via MOK (`sudo mokutil --import /var/lib/shim-signed/mok/MOK.der`, reboot, enroll). **Not tested by the author** (Secure Boot was off).

## DKMS build fails

- `linux-headers-$(uname -r)` missing → `sudo apt install linux-headers-$(uname -r)`
- Show the log: `cat /var/lib/dkms/btmtk-mt7902/1.0/build/make.log`

## After a kernel update Bluetooth stops working

DKMS rebuilds for installed header packages on new 6.17.x kernels. If the new kernel is ≥ 6.18, DKMS refuses by design — check whether it already includes the upstream fix (`uname -r` ≥ 7.1) and run `sudo ./uninstall.sh`.

## Remove everything

```sh
sudo ./uninstall.sh
```

Reports are welcome: please open an issue with the output of the commands at the top.
