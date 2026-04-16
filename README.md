# GL.iNet External USB Logs (GL-XE300 / OpenWrt)

Persistent USB log mirror for GL.iNet/OpenWrt routers that keeps **default logging behavior unchanged** while writing a copy to USB.
On branch `mudi7`, it also mirrors cellular and modem log files when those source files are present.

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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7/install.sh)"
```

---

## Installed files

- `/usr/bin/usb-log-mirror.sh`
- `/etc/init.d/usb-log-mirror`
- `/etc/usb-log-mirror.conf`
- Default log output: `<detected_mount>/gl-usb-logs/system.log` (for example `/mnt/sda1/gl-usb-logs/system.log`)
- Additional mirrored logs when source files exist: `<detected_mount>/gl-usb-logs/cellular.log` and `<detected_mount>/gl-usb-logs/modem.log`

---

## Config file (`/etc/usb-log-mirror.conf`)

`USB_MOUNT` is the preferred path to try first. If it is not present, the script can auto-detect another writable USB/SD mount and, if none is available, fall back to local storage.

```sh
# preferred mount to try first
USB_MOUNT="/mnt/sda1"

# set to 1 to auto-detect other USB/SD mounts when USB_MOUNT is unavailable
AUTO_DETECT_STORAGE="1"

# optional preferred candidates
PREFERRED_MOUNTS="/mnt/sda1 /mnt/sdb1 /mnt/mmcblk0p1 /mnt/mmcblk1p1"

# local fallback when no removable writable storage is available
FALLBACK_LOCAL_DIR="/logs-backup"

LOG_SUBDIR="gl-usb-logs"
LOG_NAME="system.log"
CELLULAR_LOG_NAME="cellular.log"
MODEM_LOG_NAME="modem.log"
CELLULAR_LOG_CANDIDATES="/tmp/quectel_slic_daemon.log /tmp/gl_modem_traffic/cpu/total_5g /tmp/gl_modem_traffic/cpu/total_4g /var/log/cellular.log /tmp/cellular.log /tmp/run/cellular.log"
MODEM_LOG_CANDIDATES="/tmp/quectel_voice_server.log /var/log/modem.log /tmp/modem.log /tmp/run/modem.log"
MAX_SIZE_KB="5120"
MAX_FILES="5"
RETRY_SECONDS="10"
CHECK_EVERY_LINES="50"
```

On a GL-E5800/Mudi 7, the default extra log candidates now prefer `/tmp/quectel_slic_daemon.log` for `cellular.log` and `/tmp/quectel_voice_server.log` for `modem.log`. Override the candidate lists in `/etc/usb-log-mirror.conf` if your firmware writes them elsewhere.

---

## Manual install commands

```sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7/usb-log-mirror.sh -o /usr/bin/usb-log-mirror.sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7/usb-log-mirror.init -o /etc/init.d/usb-log-mirror
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7/usb-log-mirror.conf -o /etc/usb-log-mirror.conf
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

# mudi7 one-liner: list and tail the mirrored system, cellular, and modem logs that exist
TARGET="$(/usr/bin/usb-log-mirror.sh check | sed -n 's/^ok: //p')" && ls -lah "$TARGET/gl-usb-logs/" && for f in system.log cellular.log modem.log; do [ -f "$TARGET/gl-usb-logs/$f" ] && echo "==> $f <==" && tail -n 5 "$TARGET/gl-usb-logs/$f"; done

# inspect the mirrored log output
TARGET="$(/usr/bin/usb-log-mirror.sh check | sed -n 's/^ok: //p')"
ls -lah "$TARGET/gl-usb-logs/"
tail -n 20 "$TARGET/gl-usb-logs/system.log"
```

---

## Uninstall

### One-line uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-ExternalUSB-Logs/mudi7/uninstall.sh)"
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

"Your router logging stays exactly the same as stock GL.iNet/OpenWrt (`logread` continues to work normally). We only add a background service that copies those logs to USB for persistence at `<detected_mount>/gl-usb-logs/system.log`, and on `mudi7` it also mirrors cellular and modem log files when those source files exist, with automatic rotation on the main system log to help prevent filling the USB drive."
