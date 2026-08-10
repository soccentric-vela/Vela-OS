# Vela-OS — Yocto embedded Linux for Qualcomm Snapdragon

## Overview

Vela-OS is the Yocto/OpenEmbedded build system for the **Vela** platform — the
**Qualcomm Snapdragon** (QCS6490 / QCM6490 / QCS5430) SoC. Default board:
**Dragonwing RB3 Gen 2** (machine `qcs6490-rb3gen2-core-kit`). Built with
[kas](https://kas.readthedocs.io/) + Docker against the `meta-qcom`
(scarthgap) layer set, with A/B OTA updates via
[swupdate](https://sbabic.github.io/swupdate/).

## Quick Start

```bash
make kas-image            # Build the KAS Docker image (once)
make image vela           # Build the Yocto image (QCS6490 RB3 Gen 2)
```

## Build Targets

```
make image  vela           Build Yocto SD card image
make build  vela           Alias for image
make rebuild-image vela    cleansstate image recipe, then rebuild
make sdk    vela           Cross-toolchain SDK installer → deploy/sdk/
make esdk   vela           Extensible SDK installer     → deploy/esdk/
make shell  vela           Interactive kas shell
make swu                    Build .swu OTA package
make flash  vela DEVICE=/dev/sdX   Flash image to SD card
```

## Boot Flow (QCS6490 RB3 Gen 2)

```
UEFI firmware → systemd-boot → Linux (boot.img + qcom/qcs6490-rb3gen2.dtb)
             → systemd → Vela-HAL, Vela services
```

## A/B OTA Layout

Partition table (`meta/meta-vela/wic/sdimage-qcom.wks`, EFI GPT):
```
  p1  /boot   EFI FAT32   systemd-boot / UKI
  p2  /       rootfs-a (active initially)
  p3  standby rootfs-b (OTA target)
  p4  /home   persistent, grown on first boot by vela-data-init
```

SWUpdate scripts switch slots by filesystem label (`rootfs-a`/`rootfs-b`).
`make swu` builds an `.swu` package; signing via
`scripts/generate-swu-keys.sh` (RSA-4096).

## Layer Structure

| Layer               | Source                        | Purpose                              |
|---------------------|-------------------------------|--------------------------------------|
| `poky`              | poky (scarthgap)              | OE core                              |
| `meta-arm`          | meta-arm (scarthgap)          | ARM BSP / ATF                        |
| `meta-oe`           | meta-openembedded (scarthgap) | Package set                          |
| `meta-qcom`         | qualcomm-linux/meta-qcom (scarthgap) | Qualcomm Snapdragon BSP   |
| `meta-swupdate`     | sbabic/meta-swupdate (scarthgap) | swupdate OTA framework           |
| `meta-vela`         | SiliconCentric/meta-vela (local, in `meta/`) | Vela image, HAL, swu config |

## Repo Notes

- `build/`, `cache/`, `sstate-cache/`, `layers/` are gitignored bind-mounted
  host dirs.
- `meta/meta-vela` is committed **locally** in this repo (see `.gitignore`);
  upstream layers are cloned by kas into `layers/` and must never be
  hand-edited.
- Qualcomm proprietary firmware/GPU/DSP binaries are accepted via
  `LICENSE_FLAGS_ACCEPTED` in `kas/common.yaml`.
