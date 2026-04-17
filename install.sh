#!/bin/sh
set -e

REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7}"
INIT_DST="/etc/init.d/usb-log-mirror"
BIN_DST="/usr/bin/usb-log-mirror.sh"
CONF_DST="/etc/usb-log-mirror.conf"

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

echo "[usb-log-mirror] Installing..."
fetch "$REPO_BASE/usb-log-mirror.sh" "$BIN_DST"
fetch "$REPO_BASE/usb-log-mirror.init" "$INIT_DST"

if [ -f "$CONF_DST" ]; then
    cp "$CONF_DST" "$CONF_DST.bak" 2>/dev/null || true
    echo "[usb-log-mirror] Backed up existing config to $CONF_DST.bak"
fi

fetch "$REPO_BASE/usb-log-mirror.conf" "$CONF_DST"
echo "[usb-log-mirror] Installed config at $CONF_DST"

chmod 0755 "$BIN_DST" "$INIT_DST"
chmod 0644 "$CONF_DST"

# Some GL.iNet/OpenWrt builds emit noisy "Command failed: Not found" errors
# for rc.common helper actions like "enable" and "restart" even when the
# service itself works. Keep install simple: start the service directly.
"$INIT_DST" stop >/dev/null 2>&1 || true
"$INIT_DST" start >/dev/null 2>&1 || true

echo "[usb-log-mirror] Done."
"$INIT_DST" status || true
