#!/bin/bash
# generate-swu-keys.sh — generate the SWUpdate RSA-4096 keypair.

set -euo pipefail

PRIV="meta/meta-vela/swupdate/keys/swupdate-private.pem"
PUB="meta/meta-vela/recipes-swupdate/vela-swupdate-config/files/swupdate-public.pem"

BITS=4096

if [ -f "${PRIV}" ]; then
    echo "ERROR: ${PRIV} already exists.  Refusing to overwrite." >&2
    exit 1
fi

mkdir -p "$(dirname "${PRIV}")"
mkdir -p "$(dirname "${PUB}")"

echo "Generating RSA-${BITS} keypair ..."
openssl genrsa -out "${PRIV}" "${BITS}"
openssl rsa -in "${PRIV}" -pubout -out "${PUB}"
echo "Done."
