#!/bin/sh
set -e

REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main}"
INIT_DST="/etc/init.d/usb-log-mirror"
BIN_DST="/usr/bin/usb-log-mirror.sh"

fetch() {
    src="$1"
    dst="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$src" -o "$dst"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dst" "$src"
    else
        echo "ERROR: curl or wget is required"
        exit 1
    fi
}

echo "Installing usb-log-mirror..."
fetch "$REPO_BASE/usb-log-mirror.sh" "$BIN_DST"
fetch "$REPO_BASE/usb-log-mirror.init" "$INIT_DST"

chmod 0755 "$BIN_DST" "$INIT_DST"

if [ -x "$INIT_DST" ]; then
    "$INIT_DST" enable
    "$INIT_DST" restart
fi

echo "Installed. Service status:"
if [ -x "$INIT_DST" ]; then
    "$INIT_DST" status || true
fi

echo "Done."
