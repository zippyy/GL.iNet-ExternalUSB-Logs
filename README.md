# GL.iNet/OpenWrt USB Log Mirror

This project adds a **persistent USB mirror** of router logs for GL.iNet/OpenWrt while keeping default logging behavior untouched.

## What it does

- Keeps normal OpenWrt/GL.iNet logging behavior (`logd`, `logread`) unchanged.
- Streams `logread -f` output to USB storage (default `/mnt/sda1/gl-usb-logs/system.log`).
- Runs as an init.d service with procd respawn.
- Handles USB-not-ready boot timing by waiting/retrying.
- Rotates log file by size (default 5 MiB, keeps 5 rotated files).

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/install.sh)"
```

## Manual install commands

```sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/usb-log-mirror.sh -o /usr/bin/usb-log-mirror.sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/usb-log-mirror.init -o /etc/init.d/usb-log-mirror
chmod +x /usr/bin/usb-log-mirror.sh /etc/init.d/usb-log-mirror
/etc/init.d/usb-log-mirror enable
/etc/init.d/usb-log-mirror restart
```

(Use `wget -qO` equivalents if curl is unavailable.)

## Verify

```sh
# Service is running
/etc/init.d/usb-log-mirror status

# Normal logread still works
logread | tail -n 20

# Persistent copy on USB
ls -lah /mnt/sda1/gl-usb-logs/
tail -n 20 /mnt/sda1/gl-usb-logs/system.log

# Generate a test entry
logger -t usb-log-mirror-test "USB mirror verification $(date -Iseconds)"
sleep 2
grep -n "usb-log-mirror-test" /mnt/sda1/gl-usb-logs/system.log | tail -n 1
```

## Uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/uninstall.sh)"
```

or manually:

```sh
/etc/init.d/usb-log-mirror stop
/etc/init.d/usb-log-mirror disable
rm -f /etc/init.d/usb-log-mirror /usr/bin/usb-log-mirror.sh
```

## Support-facing summary

"Your router keeps its normal logging in memory exactly as before, so `logread` continues to work normally. We additionally run a small background service that copies live log output to your USB drive at `/mnt/sda1/gl-usb-logs/system.log`, with automatic size-based rotation so the drive doesn’t fill up. If USB is missing during boot, normal logging is unaffected; the mirror starts automatically once USB is available."

## Optional tuning

Defaults can be overridden by setting environment variables in the init script command if needed:

- `USB_MOUNT` (default `/mnt/sda1`)
- `LOG_DIR` (default `$USB_MOUNT/gl-usb-logs`)
- `LOG_FILE` (default `$LOG_DIR/system.log`)
- `MAX_SIZE_KB` (default `5120`)
- `MAX_FILES` (default `5`)
- `CHECK_INTERVAL` (default `60` seconds)
