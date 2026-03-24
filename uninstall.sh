#!/bin/sh
set -e

INIT_DST="/etc/init.d/usb-log-mirror"
BIN_DST="/usr/bin/usb-log-mirror.sh"

echo "Uninstalling usb-log-mirror..."

if [ -x "$INIT_DST" ]; then
    "$INIT_DST" stop || true
    "$INIT_DST" disable || true
fi

rm -f "$INIT_DST" "$BIN_DST"

echo "Uninstalled."
