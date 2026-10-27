# Testing

This documents what was verified, how, and what was **not**. One machine only.

## Environment

| | |
|---|---|
| Machine | EliteMini Series, Intel Core i7-12800H |
| Wi-Fi/BT card | MediaTek MT7902 (PCIe Wi-Fi `14c3:7902`, Bluetooth over USB `0e8d:7902`) |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | `6.17.0-19-generic` (`Ubuntu 6.17.0-19.19~24.04.2`, upstream base 6.17.13) |
| Secure Boot | disabled |
| DKMS | 3.0.11 |
| Firmware | `BT_RAM_CODE_MT7902_1_1_hdr.bin` from linux-firmware.git (SHA256 matches the copy in morrownr/mt76) |

## Source provenance check

`drivers/bluetooth/btmtk.c` and `btmtk.h` from the Ubuntu kernel tag `Ubuntu-hwe-6.17-6.17.0-19.19_24.04.2` were compared with upstream `v6.17`: **0 differing lines**. The upstream patch `aab25984e5` applies with no fuzz or offset, and the result differs from the Ubuntu file by exactly the two added lines.

## Procedure and results

| # | Step | Result |
|---|---|---|
| 1 | Build against the running kernel headers (`make`) without installing | 0 errors; `vermagic` matches; `depends: bluetooth`; same `MODULE_FIRMWARE` list as the stock module |
| 2 | Stop `bluetooth`, `modprobe -r btusb btmtk`, `insmod` the patched module, `modprobe btusb` | `hci0` initialises; address valid; `UP RUNNING` |
| 3 | `bluetoothctl scan on` for 12 s | 11 devices; RX/TX errors 0 |
| 4 | `sudo ./install.sh --reload` | DKMS add/build/install OK; `modinfo -n btmtk` → `updates/dkms/btmtk.ko.zst` |
| 5 | `sudo ./uninstall.sh` | `dkms status` no longer lists it; `/usr/src/btmtk-mt7902-1.0` removed; `modinfo -n btmtk` → `kernel/drivers/bluetooth/btmtk.ko.zst`; `hci0` **broken again** (`Unsupported hardware variant (00007902)`) |
| 6 | `sudo ./install.sh --reload` again | `hci0` `UP RUNNING` again |
| 7 | Reboot | module loaded from `updates/dkms/` automatically; `hci0` `UP RUNNING`; `bluetooth.service` active; scan found 8 devices |
| 8 | Wi-Fi (separate mt76 driver) after all of the above | unaffected |

Steps 5–6 are a controlled A/B comparison: same machine, same kernel, only the `btmtk` module changes, and Bluetooth flips between broken and working.

## Before / after (kernel log and controller)

| | Stock `btmtk` | Patched `btmtk` |
|---|---|---|
| `hciconfig` | `DOWN`, `00:00:00:00:00:00`, features all 0 | `UP RUNNING`, valid address, ACL MTU 1021:6, SCO MTU 240:8 |
| Kernel log | `Unsupported hardware variant (00007902)` | `HW/SW Version: 0x008a008a, Build Time: 20250826211444`, then `Device setup in … usecs` |
| `bluetoothctl show` | no controller | `Powered: yes`, `Manufacturer: 0x0046` |

Messages that appear and are harmless here:
`HCI Enhanced Setup Synchronous Connection command is advertised, but not supported` (also present before the patch), `Failed to read MSFT supported features (-56)`, and — with out-of-tree modules — `module verification failed: signature and/or required key missing - tainting kernel`.

First manual load took ~3 s to set up the device; after reboot it took ~0.23 s. The cause was not investigated.

## Not tested

- Pairing and connecting to a real device
- A2DP / HFP audio, HID keyboards/mice
- Suspend / resume, long-running stability
- Secure Boot with MOK enrollment
- Other USB IDs (`0e8d:1ede`, `13d3:*`, `0489:e156`) and any other hardware
- Kernels other than `6.17.0-19-generic`

## Reproduce

```sh
sudo ./install.sh --reload
modinfo -n btmtk && hciconfig -a && bluetoothctl --timeout 10 scan on
sudo ./uninstall.sh            # hci0 should be broken again on a 6.17 kernel
```
