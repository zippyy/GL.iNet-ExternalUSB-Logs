# GL.iNet External USB Logs (GL-XE300 / OpenWrt)

Persistent USB log mirror for GL.iNet/OpenWrt routers that keeps **default logging behavior unchanged** while writing a copy to USB.

---

## Why this exists

OpenWrt keeps system logs in memory by default. That is fast and normal, but logs are lost after reboot.
This project mirrors logs to USB so they survive reboots while preserving normal `logread` behavior.

---

## Guarantees

- ✅ Does **not** replace `logd` destination.
- ✅ Keeps normal `logread` behavior.
- ✅ Adds a second persistent copy on USB.
- ✅ Waits/retries if USB is not mounted yet.
- ✅ Includes size-based rotation.

---

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main/install.sh)"
```

---

## Installed files

- `/usr/bin/usb-log-mirror.sh`
- `/etc/init.d/usb-log-mirror`
- `/etc/usb-log-mirror.conf`
- Default log output: `<detected_mount>/gl-usb-logs/system.log` (for example `/mnt/sda1/gl-usb-logs/system.log`)

---

## Config file (`/etc/usb-log-mirror.conf`)

```sh
USB_MOUNT="/mnt/sda1"
AUTO_DETECT_STORAGE="1"
PREFERRED_MOUNTS="/mnt/sda1 /mnt/sdb1 /mnt/mmcblk0p1 /mnt/mmcblk1p1"
LOG_SUBDIR="gl-usb-logs"
LOG_NAME="system.log"
MAX_SIZE_KB="5120"
MAX_FILES="5"
RETRY_SECONDS="10"
CHECK_EVERY_LINES="50"
```

---

## Manual install commands

```sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main/usb-log-mirror.sh -o /usr/bin/usb-log-mirror.sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main/usb-log-mirror.init -o /etc/init.d/usb-log-mirror
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main/usb-log-mirror.conf -o /etc/usb-log-mirror.conf
chmod +x /usr/bin/usb-log-mirror.sh /etc/init.d/usb-log-mirror
chmod 0644 /etc/usb-log-mirror.conf
/etc/init.d/usb-log-mirror enable
/etc/init.d/usb-log-mirror restart
```

---

## Verify

`check` always prints `ok: <path>` on success, whether the active target is a USB/SD mount or the local fallback path. That keeps this simple parse stable:

```sh
# service status
/etc/init.d/usb-log-mirror status

# normal OpenWrt logs still work
logread | tail -n 20

# show the active target path
/usr/bin/usb-log-mirror.sh check

# simple one-liner: write a test entry and show the newest mirrored match
TARGET="$(/usr/bin/usb-log-mirror.sh check | sed -n 's/^ok: //p')" && logger -t usb-log-mirror-test "USB mirror verification $(date -Iseconds)" && sleep 2 && grep -n "usb-log-mirror-test" "$TARGET/gl-usb-logs/system.log" | tail -n 1

# inspect the mirrored log output
TARGET="$(/usr/bin/usb-log-mirror.sh check | sed -n 's/^ok: //p')"
ls -lah "$TARGET/gl-usb-logs/"
tail -n 20 "$TARGET/gl-usb-logs/system.log"
```

---

## Uninstall

### One-line uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/main/uninstall.sh)"
```

### Manual uninstall

```sh
/etc/init.d/usb-log-mirror stop
/etc/init.d/usb-log-mirror disable
rm -f /etc/init.d/usb-log-mirror /usr/bin/usb-log-mirror.sh
# optional: rm -f /etc/usb-log-mirror.conf
```

---

## End-user support message

"Your router logging stays exactly the same as stock GL.iNet/OpenWrt (`logread` continues to work normally). We only add a background service that copies those logs to USB for persistence at `<detected_mount>/gl-usb-logs/system.log`, with automatic rotation to help prevent filling the USB drive."
