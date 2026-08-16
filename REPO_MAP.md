# Vela-OS

**Remote:** `git@github.com:soccentric-vela/Vela-OS.git`
**Parent project:** [Vela](../Vela.md) (target hardware: **Qualcomm Snapdragon** QCS6490 / QCM6490 / QCS5430.)
**Leaf type:** `<Project>-OS`
**Status:** REAL — actively built out

Yocto-based embedded Linux OS for the **Qualcomm Snapdragon** platform.
Built with `kas` + Docker against the `meta-qcom` (scarthgap) layer set, with
A/B OTA via `swupdate`.

**Board:** default `vela` (machine `qcom-armv8a`, Dragonwing RB3
Gen 2). Platform customization lives in `meta/meta-vela`, a nested clone of its
own upstream `soccentric-vela/meta-vela` (fetched by kas);
upstream layers (`poky`, `meta-arm`, `meta-openembedded`, `meta-qcom`,
`meta-swupdate`) are checked out by kas into a **gitignored** `layers/`
directory and must never be hand-edited.

**Targets:** `make build`, `make image`, `make shell [board]`, `make swu`,
`make sdk`/`esdk`, `make flash`, `make deploy-*`, `make clean`/`clean-all`.

**Boot flow (QCS6490 RB3 Gen 2):**
```
UEFI firmware → systemd-boot → Linux (boot.img + qcom/qcs6490-rb3gen2.dtb)
             → systemd → Vela-HAL, Vela services
```

**A/B OTA layout:** EFI GPT — `boot` (FAT32, systemd-boot/UKI), `rootfs-a`,
`rootfs-b` (switched by swupdate via filesystem label), `data` (`/home`,
persistent). See `meta/meta-vela/wic/sdimage-qcom.wks`.

**Local layer:** `meta/meta-vela` is a nested clone with its own upstream
at `soccentric-vela/meta-vela.git` (see `.gitignore`).

---
Part of the `Vela` project in the `project-managers` fleet. See
`docs/project-managers.md` for the full 9-project / 8-leaf hierarchy and shared
conventions.
