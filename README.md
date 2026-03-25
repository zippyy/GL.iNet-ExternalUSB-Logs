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
FALLBACK_LOCAL_DIR="/logs-backup"
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

# One liner to check path:
/usr/bin/usb-log-mirror.sh check

# check selected target:
# - "ok: <mount>" means USB/SD storage is active
# - "ok-local: /logs-backup" means local fallback is active
CHECK_OUT="$(/usr/bin/usb-log-mirror.sh check)"
printf '%s\n' "$CHECK_OUT"

if printf '%s\n' "$CHECK_OUT" | grep -q '^ok: '; then
  MOUNT="$(printf '%s\n' "$CHECK_OUT" | sed -n 's/^ok: //p')"
  TARGET="$MOUNT"
elif printf '%s\n' "$CHECK_OUT" | grep -q '^ok-local: '; then
  TARGET="$(printf '%s\n' "$CHECK_OUT" | sed -n 's/^ok-local: //p')"
else
  echo "usb-log-mirror target is not ready"
  exit 1
fi

# check mirror output on active target
ls -lah "$TARGET/gl-usb-logs/"
tail -n 20 "$TARGET/gl-usb-logs/system.log"

# generate a test log line and confirm it lands in mirror
logger -t usb-log-mirror-test "USB mirror verification $(date -Iseconds)"
sleep 2
grep -n "usb-log-mirror-test" "$TARGET/gl-usb-logs/system.log" | tail -n 1
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

"Your router logging stays exactly the same as stock GL.iNet/OpenWrt (`logread` continues to work normally). We only add a background service that copies those logs to persistent storage at `<detected_mount>/gl-usb-logs/system.log` when USB/SD storage is available, or `/logs-backup/gl-usb-logs/system.log` when local fallback is active, with automatic rotation to help prevent filling storage."
