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

Messages observed during these tests (they did not prevent initialization, scanning or the tested data transfers; SCO/audio behavior was not evaluated):
`HCI Enhanced Setup Synchronous Connection command is advertised, but not supported` (also present before the patch), `Failed to read MSFT supported features (-56)`, and — with out-of-tree modules — `module verification failed: signature and/or required key missing - tainting kernel`.

First manual load took ~3 s to set up the device; after reboot it took ~0.23 s. The cause was not investigated.

## Not tested

- Pairing and connecting on the original 6.17 setup (pairing and OBEX transfer were subsequently tested on 7.0)
- A2DP / HFP audio, HID keyboards/mice
- Long-running stability; suspend/resume was subsequently tested on 7.0
- Secure Boot with MOK enrollment
- Other USB IDs (`0e8d:1ede`, `13d3:*`, `0489:e156`) and any other hardware
- Kernel variants other than the specifically tested 6.17 and 7.0 builds

## Reproduce

```sh
sudo ./install.sh --reload
modinfo -n btmtk && hciconfig -a && bluetoothctl --timeout 10 scan on
sudo ./uninstall.sh            # hci0 should be broken again on a 6.17 kernel
```

## 2026-11-10: Ubuntu kernel 7.0

Package 1.0's 6.17-only guard skipped builds after the machine upgraded to `7.0.0-38-generic`. The stock `btmtk` then reported `Unsupported hardware variant (00007902)` again.

Package 1.1 adds a separate `src-7.0/` baseline from Ubuntu tag `Ubuntu-hwe-7.0-7.0.0-38.38_24.04.4`. The diff against that baseline is limited to the same two upstream MT7902 additions. It compiled against the installed 7.0 headers and loaded from `updates/dkms/`. Secure Boot remained disabled.

| Check | Observed result |
|---|---|
| Module load | Valid controller address, `UP RUNNING` |
| Pairing with an Android phone | Paired and bonded |
| OBEX Object Push | Generated 4,141-byte text file, `Status=complete`; accepted on the phone |
| L2CAP echo | 5 sent, 5 received, 0% loss |
| 6.17 build regression | Both original 6.17 sources still compile against `6.17.0-19-generic` headers |
| 7.0 suspend/resume | Entered S3/deep sleep with an RTC wake alarm; both Wi-Fi devices reconnected automatically and both Bluetooth radios passed 5/5 L2CAP echo requests after wake |
| 7.0 reboot | Fresh boot ID confirmed; patched module loaded automatically (loaded and installed srcversion both `E03D2B2611AA9805F2AFB22`), valid powered controller; 5/5 L2CAP echoes after reboot |

Pairing and transfer on 7.0 supersede the earlier untested status for those operations only. They do not establish audio, HID or long-running reliability.

### Recovery coverage

The same machine also had an independent RTL8822BU USB Wi-Fi/Bluetooth adapter installed. Both Wi-Fi interfaces reconnected to a 5 GHz Android hotspot after S3 resume and reboot. A physical unplug/replug of the USB adapter restored its Wi-Fi connection and retained its phone Bluetooth bond; L2CAP echo returned 5/5. These USB results are a coexistence check, not a claim that this package modifies the Realtek driver.

During 60-second upload and 60-second download tests on the Realtek Wi-Fi interface, each Bluetooth radio also completed 20/20 L2CAP echoes. The stock Realtek Wi-Fi driver was retained. Wi-Fi power saving was disabled for the test connections, and USB runtime autosuspend was disabled for the specific Realtek device. No audio-quality or HID conclusions follow from these tests.
