#!/bin/bash
# SWUpdate post-install script for Sequoia Intel x86 A/B rootfs updates.

set -euo pipefail

TARGET_SLOT=$(cat /run/swupdate-target-slot)
TARGET_DEV=$(cat /run/swupdate-target-dev)
TARGET_LABEL="rootfs-${TARGET_SLOT}"
TARGET_ROOT_ARG="root=LABEL=${TARGET_LABEL}"

echo "[swupdate post-install] activating slot ${TARGET_SLOT} (${TARGET_DEV}, label=${TARGET_LABEL})"

BOOT_WAS_RO=0
if findmnt -n -o OPTIONS /boot 2>/dev/null | grep -qw ro; then
    BOOT_WAS_RO=1
fi
mount -o remount,rw /boot 2>/dev/null || true

UPDATED=0

if [[ -f /boot/cmdline.txt ]]; then
    sed -Ei "s#root=[^ ]+#${TARGET_ROOT_ARG}#" /boot/cmdline.txt
    UPDATED=1
fi

if compgen -G "/boot/loader/entries/*.conf" > /dev/null; then
    for entry in /boot/loader/entries/*.conf; do
        sed -Ei "s#root=[^ ]+#${TARGET_ROOT_ARG}#" "${entry}"
    done
    UPDATED=1
fi

for grub_cfg in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
    if [[ -f "${grub_cfg}" ]]; then
        sed -Ei "s#root=[^ ]+#${TARGET_ROOT_ARG}#g" "${grub_cfg}"
        UPDATED=1
    fi
done

if [[ "${UPDATED}" -eq 0 ]]; then
    echo "[swupdate post-install] ERROR: no supported boot config found under /boot" >&2
    exit 1
fi

if [[ "${BOOT_WAS_RO}" -eq 1 ]]; then
    mount -o remount,ro /boot 2>/dev/null || true
fi

echo "[swupdate post-install] boot config updated to ${TARGET_ROOT_ARG}"

rm -f /dev/swupdate-inactive \
      /run/swupdate-target-slot \
      /run/swupdate-target-dev
