#!/bin/bash
# SWUpdate pre-install script for Sequoia Intel x86 A/B rootfs updates.

set -euo pipefail

ACTIVE_DEV=$(findmnt -n -o SOURCE /)
ACTIVE_LABEL=$(blkid -o value -s LABEL "${ACTIVE_DEV}" 2>/dev/null || true)

echo "[swupdate pre-install] active root: ${ACTIVE_DEV} (label=${ACTIVE_LABEL})"

case "${ACTIVE_LABEL}" in
    rootfs-a)
        INACTIVE_LABEL=rootfs-b
        INACTIVE_SLOT=b
        ;;
    rootfs-b)
        INACTIVE_LABEL=rootfs-a
        INACTIVE_SLOT=a
        ;;
    *)
        echo "[swupdate pre-install] ERROR: expected rootfs-a/rootfs-b, got '${ACTIVE_LABEL}'" >&2
        exit 1
        ;;
esac

INACTIVE_DEV=$(blkid -L "${INACTIVE_LABEL}" 2>/dev/null || true)
if [[ -z "${INACTIVE_DEV}" ]]; then
    echo "[swupdate pre-install] ERROR: cannot find device for label ${INACTIVE_LABEL}" >&2
    exit 1
fi

echo "[swupdate pre-install] target slot: ${INACTIVE_SLOT} (${INACTIVE_DEV})"

ln -sf "${INACTIVE_DEV}" /dev/swupdate-inactive

echo "${INACTIVE_SLOT}" > /run/swupdate-target-slot
echo "${INACTIVE_DEV}" > /run/swupdate-target-dev
