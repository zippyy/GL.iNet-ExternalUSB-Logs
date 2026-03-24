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

```sh
# service status
/etc/init.d/usb-log-mirror status

# normal OpenWrt logs still work
logread | tail -n 20

# detect which USB/SD mount is currently selected
/usr/bin/usb-log-mirror.sh check
MOUNT="$(/usr/bin/usb-log-mirror.sh check | sed -n "s/^ok: //p")"

# check mirror output on selected mount
ls -lah "$MOUNT/gl-usb-logs/"
tail -n 20 "$MOUNT/gl-usb-logs/system.log"

# generate a test log line and confirm it lands in USB mirror
logger -t usb-log-mirror-test "USB mirror verification $(date -Iseconds)"
sleep 2
grep -n "usb-log-mirror-test" "$MOUNT/gl-usb-logs/system.log" | tail -n 1
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
