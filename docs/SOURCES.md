# Source baselines

The two supported kernel series use separate Ubuntu source files. Existing fixes in the newer kernel are retained. Both baselines receive only the MT7902 chip-ID case and firmware-name definition from upstream commit `aab25984e55972e53f3e58821cb85a7101876056`. The original ISC notices remain intact.

| Directory | Ubuntu tag |
|---|---|
| `src/` | `Ubuntu-hwe-6.17-6.17.0-19.19_24.04.2` |
| `src-7.0/` | `Ubuntu-hwe-7.0-7.0.0-38.38_24.04.4` |

Ubuntu repository: https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/noble/

## Unmodified 7.0 baseline hashes

```text
39b8dd4009f8e4411c52e30bf574d0ee67106af2944de220cf0db95c28647293  btmtk.c
4b5d3781d0d8e47e3282c53564e83892793bb4a18c5ca318e821220316bcd9f3  btmtk.h
```

To inspect the two changes, fetch the files from `drivers/bluetooth/` at the stated tag and diff them against `src-7.0/`. No `btusb` changes or firmware binaries are distributed in this package.
