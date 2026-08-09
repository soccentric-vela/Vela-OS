#!/bin/bash
# swupdate-bootcheck - runs once per boot, logs the active slot.

set -euo pipefail

ACTIVE_DEV=$(findmnt -n -o SOURCE / 2>/dev/null || echo "unknown")
ACTIVE_LABEL=$(blkid -o value -s LABEL "${ACTIVE_DEV}" 2>/dev/null || echo "unknown")

case "${ACTIVE_LABEL}" in
    rootfs-a) SLOT=a ;;
    rootfs-b) SLOT=b ;;
    *) SLOT=unknown ;;
esac

logger -t swupdate-bootcheck "Boot confirmed: slot=${SLOT} dev=${ACTIVE_DEV} label=${ACTIVE_LABEL}"
echo "slot=${SLOT}" > /run/swupdate-active-slot
