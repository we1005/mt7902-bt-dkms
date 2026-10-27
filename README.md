# mt7902-bt-dkms

**Bluetooth for the MediaTek MT7902 on Linux 6.17 — a DKMS backport of the upstream `btmtk` patch.**

[![CI](https://github.com/we1005/mt7902-bt-dkms/actions/workflows/ci.yml/badge.svg)](https://github.com/we1005/mt7902-bt-dkms/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Kernel](https://img.shields.io/badge/kernel-6.17.x-orange.svg)](#compatibility)
[![Upstream](https://img.shields.io/badge/upstream-Linux%207.1-success.svg)](https://git.kernel.org/torvalds/c/aab25984e559)

English · [简体中文](README.zh-CN.md)

---

## The problem

On Ubuntu 24.04 (HWE kernel 6.17) the Bluetooth half of a **MediaTek MT7902** (Filogic 310, Wi-Fi 6E + Bluetooth combo card) does not work:

```console
$ dmesg | grep hci0
Bluetooth: hci0: Unsupported hardware variant (00007902)

$ hciconfig -a
hci0:  Type: Primary  Bus: USB
       BD Address: 00:00:00:00:00:00  ...
       DOWN
```

`btusb` binds the USB device and creates `hci0`, but `btmtk` does not know chip ID `0x7902`, so the firmware is never loaded.

## The fix

MediaTek's Sean Wang fixed this upstream with a **two-line** change, merged for **Linux 7.1**:
[`aab25984e559` — *Bluetooth: btmtk: add MT7902 MCU support*](https://git.kernel.org/torvalds/c/aab25984e559).

This repository packages that change for **6.17** as a small DKMS module:

```diff
--- a/drivers/bluetooth/btmtk.c
+++ b/drivers/bluetooth/btmtk.c
@@ btmtk_usb_setup()
 	case 0x7922:
 	case 0x7925:
 	case 0x7961:
+	case 0x7902:
--- a/drivers/bluetooth/btmtk.h
+++ b/drivers/bluetooth/btmtk.h
+#define FIRMWARE_MT7902		"mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin"
```

> **This is not a new driver and not original driver work.** The change is MediaTek's, verbatim (author and sign-offs preserved in [`patches/`](patches/)). What this repo adds is the packaging for 6.17, the install/uninstall scripts, and a documented verification.
>
> **The Wi-Fi half of the MT7902 is a different driver (mt76) and is not covered here.** See [morrownr/mt76](https://github.com/morrownr/mt76) for an out-of-tree Wi-Fi driver.

## Quick start

```sh
# prerequisites (Debian/Ubuntu)
sudo apt install dkms build-essential linux-headers-$(uname -r)

git clone https://github.com/we1005/mt7902-bt-dkms.git
cd mt7902-bt-dkms
sudo ./install.sh --reload      # omit --reload to activate after the next reboot
```

Verify:

```sh
modinfo -n btmtk                           # .../updates/dkms/btmtk.ko.zst
hciconfig -a                               # hci0 UP RUNNING, BD Address not all zeros
bluetoothctl --timeout 10 scan on         # nearby devices show up
```

Remove it (restores the in-kernel module):

```sh
sudo ./uninstall.sh
```

## How it works

```
                  ┌────────────┐
 USB 0e8d:7902 ──▶│   btusb    │  binds via the generic MediaTek rule
                  └─────┬──────┘  USB_VENDOR_AND_INTERFACE_INFO(0x0e8d, 0xe0, 0x01, 0x01)
                        │ btmtk_usb_setup()
                  ┌─────▼──────┐
                  │   btmtk    │◀── replaced by this package (case 0x7902)
                  └─────┬──────┘
                        │ request_firmware("mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin")
                  ┌─────▼──────┐
                  │ bluetooth  │  untouched
                  └────────────┘
```

The patched `btmtk` is built as a module with the **same name** and installed to `/lib/modules/<ver>/updates/dkms/`. `depmod` prefers `updates/` over `kernel/`, so the stock module is shadowed — no blacklisting. `btusb` and the Bluetooth core are not modified. DKMS rebuilds it for new 6.17.x kernel packages.

## Compatibility

| | |
|---|---|
| Kernel | **6.17.x only** (enforced by `BUILD_EXCLUSIVE_KERNEL="^6\.17\."` in `dkms.conf`). The bundled source is Ubuntu `Ubuntu-hwe-6.17-6.17.0-19.19_24.04.2`, which is byte-identical to upstream v6.17 for `btmtk.c`/`btmtk.h`. |
| Kernel ≥ 7.1 | **Do not use** — the support is already in-tree, and the bundled `btmtk.c` would be older than the kernel's. Run `./uninstall.sh`. |
| Other series (6.18 – 7.0, ≤ 6.16) | Untested and refused by DKMS. |
| Firmware | `/lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin` must exist. Ubuntu 24.04's stock `linux-firmware` (20240318) does **not** ship it — take it from [linux-firmware.git](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/mediatek). `install.sh` warns if it is missing. |

### Which MT7902 Bluetooth devices does this help?

This package only touches `btmtk`. It therefore only helps devices that the **6.17** `btusb` already binds **with the MediaTek flag**, i.e. USB vendor `0e8d` with interface class `e0/01/01`. That is the case for `0e8d:7902` (tested).

Upstream 7.1 also added explicit `btusb` entries for other MT7902 variants. On 6.17 these are **not** covered by this package, because their `btusb` binding would also need to change:

| USB ID | Status with this package |
|---|---|
| `0e8d:7902` | ✅ tested |
| `0e8d:1ede` | ❔ should bind via the `0e8d` rule — untested |
| `13d3:3579`, `13d3:3580`, `13d3:3594`, `13d3:3596` | ❌ not helped (6.17 `btusb` has no MediaTek flag for them) |
| `0489:e156` | ❌ not helped |

Check yours with `lsusb | grep -iE '0e8d|13d3|0489'`. Support for these IDs would need a patched `btusb` as well — see [Roadmap](#roadmap).

## Tested

One machine so far. **Reports from other hardware are very welcome** — see [CONTRIBUTING](CONTRIBUTING.md).

| | |
|---|---|
| Hardware | EliteMini Series (Intel i7-12800H), MT7902, Bluetooth USB `0e8d:7902` |
| OS | Ubuntu 24.04.4, `6.17.0-19-generic` (`6.17.0-19.19~24.04.2`), Secure Boot **disabled** |
| Before | `Unsupported hardware variant (00007902)`, all-zero address, `DOWN` |
| After | firmware loaded (build `20250826211444`), `UP RUNNING`, valid address, BlueZ sees the controller |
| Scan | 11 and 8 devices found in two runs, 0 errors |
| Rollback | `uninstall.sh` returns to the broken stock behaviour, `install.sh` restores it (same machine, same kernel — only `btmtk` changes) |
| Reboot | module is picked up from `updates/dkms/` automatically, `hci0` comes up |

**Not tested:** pairing/connecting, A2DP/HFP audio, HID devices, suspend/resume, long-running stability, Secure Boot with MOK enrollment, any other hardware.

Details: [docs/TESTING.md](docs/TESTING.md).

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). The common ones:

- `hci0` still shows an all-zero address after install → run `sudo ./install.sh --reload`, or reboot; check `modinfo -n btmtk` points to `updates/dkms`.
- `Direct firmware load for mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin failed` → the firmware file is missing (see Compatibility).
- `Key was rejected by service` / module not loading with Secure Boot enabled → the DKMS signing key has to be enrolled (MOK); not tested here.

## Roadmap

- [ ] Confirm pairing, audio and suspend/resume on real devices
- [ ] Optional `btusb` patch for the extra MT7902 USB IDs added in 7.1 (needs hardware to test)
- [ ] Cherry-pick the 7.1 `btmtk` robustness fixes if firmware download turns out to be flaky (deliberately **not** included — minimal change first)
- [ ] Test other Ubuntu kernel flavours (`-lowlatency`, `-oem`) and Debian
- [ ] Retire this repository once Ubuntu's 24.04 HWE kernel ships the upstream patch

## Credits

- **Sean Wang** (MediaTek) — author of the upstream patch; **Luiz Augusto von Dentz** — Bluetooth maintainer who merged it.
- [morrownr/mt76](https://github.com/morrownr/mt76) — the Wi-Fi side of the same chip, and the repo that pointed to the right upstream commits.

## License

- `src/btmtk.c`, `src/btmtk.h` — Copyright (C) 2021 MediaTek Inc., **ISC** (SPDX header kept as in the kernel tree). `MODULE_LICENSE("GPL")` as in the original.
- Everything else (Makefile, Kbuild, `dkms.conf`, scripts, docs) — **MIT**, Copyright (c) 2026 ljc. See [LICENSE](LICENSE).
- The patch in [`patches/`](patches/) is the unmodified upstream commit.

License texts are in [`LICENSES/`](LICENSES/).
