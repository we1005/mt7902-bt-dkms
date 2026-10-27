# mt7902-bt-dkms

**让 MediaTek MT7902 的蓝牙在 Linux 6.17 上可用：上游 `btmtk` 补丁的 DKMS 回移植。**

[English](README.md) · 简体中文

---

## 问题

在 Ubuntu 24.04（HWE 内核 6.17）上，**MediaTek MT7902**（Filogic 310，Wi-Fi 6E + 蓝牙二合一）的**蓝牙**不工作：

```console
$ dmesg | grep hci0
Bluetooth: hci0: Unsupported hardware variant (00007902)

$ hciconfig -a
hci0:  Type: Primary  Bus: USB
       BD Address: 00:00:00:00:00:00  ...
       DOWN
```

`btusb` 已经绑定了 USB 设备并创建了 `hci0`，但 `btmtk` 不认识芯片 ID `0x7902`，所以从不加载固件。

## 解决

MediaTek 的 Sean Wang 已在上游用**两行**改动修好，合入 **Linux 7.1**：
[`aab25984e559` — *Bluetooth: btmtk: add MT7902 MCU support*](https://git.kernel.org/torvalds/c/aab25984e559)。

本仓库把这个改动打包成适用于 **6.17** 的小型 DKMS 模块：`btmtk.c` 里加一行 `case 0x7902:`，`btmtk.h` 里加一行 `FIRMWARE_MT7902` 固件路径定义。

> **这不是新写的驱动，也不是原创的驱动工作。** 改动本身是 MediaTek 的，原样保留（作者与签名见 [`patches/`](patches/)）。本仓库做的是：为 6.17 打包、安装/卸载脚本、以及有记录的验证。
>
> **MT7902 的 Wi-Fi 部分是另一个驱动（mt76），不在本仓库范围内**，可参考 [morrownr/mt76](https://github.com/morrownr/mt76)。

## 快速开始

```sh
# 依赖（Debian/Ubuntu）
sudo apt install dkms build-essential linux-headers-$(uname -r)

git clone https://github.com/we1005/mt7902-bt-dkms.git
cd mt7902-bt-dkms
sudo ./install.sh --reload      # 不加 --reload 则下次重启后生效
```

验证：

```sh
modinfo -n btmtk                           # .../updates/dkms/btmtk.ko.zst
hciconfig -a                               # hci0 UP RUNNING，BD Address 不再全零
bluetoothctl --timeout 10 scan on         # 能扫到周围设备
```

卸载（恢复内核自带模块）：

```sh
sudo ./uninstall.sh
```

## 原理

打过补丁的 `btmtk` 编译成**同名**模块，装到 `/lib/modules/<版本>/updates/dkms/`。`depmod` 默认让 `updates/` 优先于 `kernel/`，因此内核自带的模块被遮蔽，不需要 `blacklist`。`btusb` 和蓝牙核心都没有改动。内核升级到新的 6.17.x 时，DKMS 会自动重新编译。

## 兼容性

| | |
|---|---|
| 内核 | **只支持 6.17.x**（`dkms.conf` 里 `BUILD_EXCLUSIVE_KERNEL="^6\.17\."` 强制）。内置的源码来自 Ubuntu `Ubuntu-hwe-6.17-6.17.0-19.19_24.04.2`，这两个文件与上游 v6.17 逐字相同 |
| 内核 ≥ 7.1 | **不要使用**：内核已自带支持，而且本仓库的 `btmtk.c` 比内核的旧。请运行 `./uninstall.sh` |
| 其他版本（6.18–7.0、≤ 6.16） | 未测试，DKMS 会拒绝构建 |
| 固件 | 必须有 `/lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin`。Ubuntu 24.04 自带的 `linux-firmware`（20240318）**没有**，请从 [linux-firmware.git](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/mediatek) 获取；缺失时 `install.sh` 会警告 |

### 哪些 MT7902 蓝牙设备能用？

本模块只改 `btmtk`，所以只对 **6.17 的 `btusb` 已经带着 MediaTek 标志绑定**的设备有效：USB 厂商 `0e8d`、接口类 `e0/01/01`。`0e8d:7902` 满足（已测试）。

上游 7.1 还给其他 MT7902 变体新增了显式的 `btusb` 条目，这些在 6.17 上**本包帮不到**，因为还需要改 `btusb` 的绑定：

| USB ID | 使用本包的情况 |
|---|---|
| `0e8d:7902` | ✅ 已测试 |
| `0e8d:1ede` | ❔ 应该会走 `0e8d` 通配规则，未测试 |
| `13d3:3579`、`13d3:3580`、`13d3:3594`、`13d3:3596` | ❌ 帮不到（6.17 `btusb` 对它们没有 MediaTek 标志） |
| `0489:e156` | ❌ 帮不到 |

用 `lsusb | grep -iE '0e8d|13d3|0489'` 查看你的设备。要支持这些 ID 还需要同时打 `btusb` 补丁，见下方路线图。

## 验证情况

目前只在一台机器上测过，**欢迎其他硬件的反馈**（见 [CONTRIBUTING](CONTRIBUTING.md)）。

| | |
|---|---|
| 硬件 | EliteMini Series（Intel i7-12800H），MT7902，蓝牙 USB `0e8d:7902` |
| 系统 | Ubuntu 24.04.4，`6.17.0-19-generic`，Secure Boot **关闭** |
| 修复前 | `Unsupported hardware variant (00007902)`，地址全零，`DOWN` |
| 修复后 | 固件加载成功（build `20250826211444`），`UP RUNNING`，地址有效，BlueZ 识别控制器 |
| 扫描 | 两次分别发现 11 个、8 个设备，错误 0 |
| 回滚 | `uninstall.sh` 回到不可用状态，`install.sh` 恢复（同机同内核，只换 `btmtk`） |
| 重启 | 自动从 `updates/dkms/` 加载，`hci0` 自动起来 |

**没测：** 配对与连接、A2DP/HFP 音频、HID 设备、休眠唤醒、长时间稳定性、开启 Secure Boot 的 MOK 流程、任何其他硬件。

详情：[docs/TESTING.md](docs/TESTING.md)。故障排查：[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。

## 路线图

- [ ] 在真实设备上确认配对、音频、休眠唤醒
- [ ] 为 7.1 新增的其他 MT7902 USB ID 提供可选的 `btusb` 补丁（需要硬件才能测）
- [ ] 如果固件下载不稳，再挑选 7.1 里 `btmtk` 的稳定性修复（目前**刻意不带**：先做最小改动）
- [ ] 测试其他 Ubuntu 内核变体（`-lowlatency`、`-oem`）和 Debian
- [ ] Ubuntu 24.04 HWE 内核自带该补丁后，归档本仓库

## 致谢

- **Sean Wang**（MediaTek）：上游补丁作者；**Luiz Augusto von Dentz**：合入补丁的蓝牙子系统维护者。
- [morrownr/mt76](https://github.com/morrownr/mt76)：同一芯片的 Wi-Fi 侧，也是它指引我找到相关的上游提交。

## 许可证

- `src/btmtk.c`、`src/btmtk.h`：Copyright (C) 2021 MediaTek Inc.，**ISC**（保留内核源码中的 SPDX 头），`MODULE_LICENSE("GPL")` 与原文件一致。
- 其余文件（Makefile、Kbuild、`dkms.conf`、脚本、文档）：**MIT**，Copyright (c) 2026 ljc，见 [LICENSE](LICENSE)。
- [`patches/`](patches/) 中的补丁是未修改的上游提交。

许可证全文见 [`LICENSES/`](LICENSES/)。
