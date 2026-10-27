# Contributing

Thanks for helping. The most valuable contribution right now is **a test report from hardware that is not the author's** — only one machine has been tested.

## Send a test report

Open a *Hardware report* issue and include:

```sh
uname -r
lsusb | grep -iE '0e8d|13d3|0489'
dkms status
modinfo -n btmtk
hciconfig -a
sudo dmesg | grep -iE 'hci0|btmtk|btusb'
bluetoothctl --timeout 10 scan on
```

Please also say what you tried beyond scanning (pairing, audio, suspend). Remove anything you consider private (MAC addresses, hostnames).

## Report a bug

Use the *Bug report* issue template. Include kernel version, USB ID and the log lines above.

## Code changes

- Keep `src/btmtk.c` / `src/btmtk.h` as close as possible to the kernel sources. Any change beyond the upstream MT7902 patch must (a) point to the upstream commit it comes from, and (b) be added as a separate file in `patches/` so the origin stays visible.
- Do not remove authorship or `Signed-off-by` lines from upstream patches.
- Scripts must stay POSIX `sh` and pass `shellcheck`.
- Every source file needs an SPDX header (`MIT` for this repo's own files, the original `ISC` for `btmtk.{c,h}`).
- Update `CHANGELOG.md` and the *Tested* section only with things you actually ran.

## Scope

In scope: making MT7902 Bluetooth work on 6.17 via DKMS; additional `btusb` USB ID support if it can be tested on real hardware.
Out of scope: Wi-Fi (see [morrownr/mt76](https://github.com/morrownr/mt76)), kernels that already contain the upstream fix.
