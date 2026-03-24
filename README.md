# GL.iNet USB Logs

A GL.iNet/OpenWrt companion script for **GL-XE300 (Puli)** and similar models that keeps default router logging intact while also writing a persistent copy of logs to USB storage.

---

## ✅ What this script does

- Keeps the default OpenWrt logging pipeline untouched (`logd` ring buffer, standard `logread`).
- Mirrors live logs to USB storage (default: `/mnt/sda1/gl-usb-logs/system.log`).
- Starts automatically at boot using init.d/procd.
- Survives USB timing issues at boot (waits/retries until USB is mounted and writable).
- Adds size-based log rotation to reduce risk of filling USB.

## ❌ What this script does **not** do

- Does **not** change your normal log destination.
- Does **not** replace `logd` with a single file logger.
- Does **not** break or alter normal `logread` behavior.

---

## 🚀 One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/install.sh)"
```

---

## 📦 Installed files

- `/usr/bin/usb-log-mirror.sh`
- `/etc/init.d/usb-log-mirror`
- USB log path (default): `/mnt/sda1/gl-usb-logs/system.log`

---

## 🔧 Manual install (exact commands)

```sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/usb-log-mirror.sh -o /usr/bin/usb-log-mirror.sh
curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/usb-log-mirror.init -o /etc/init.d/usb-log-mirror
chmod +x /usr/bin/usb-log-mirror.sh /etc/init.d/usb-log-mirror
/etc/init.d/usb-log-mirror enable
/etc/init.d/usb-log-mirror restart
```

> If `curl` is unavailable, replace with equivalent `wget -qO` commands.

---

## 🧪 Verification (exact commands)

```sh
# 1) Service state
/etc/init.d/usb-log-mirror status

# 2) Confirm normal logread still works
logread | tail -n 20

# 3) Confirm USB log files exist
ls -lah /mnt/sda1/gl-usb-logs/

# 4) Write a test entry and confirm it appears on USB
logger -t usb-log-mirror-test "USB mirror verification $(date -Iseconds)"
sleep 2
grep -n "usb-log-mirror-test" /mnt/sda1/gl-usb-logs/system.log | tail -n 1

# 5) Inspect the persistent mirror
tail -n 20 /mnt/sda1/gl-usb-logs/system.log
```

---

## ⚙️ Defaults and tuning

Current defaults:

- `USB_MOUNT=/mnt/sda1`
- `LOG_DIR=$USB_MOUNT/gl-usb-logs`
- `LOG_FILE=$LOG_DIR/system.log`
- `MAX_SIZE_KB=5120` (5 MiB)
- `MAX_FILES=5`
- `CHECK_INTERVAL=60` seconds

If needed, these can be overridden by environment variables in the service command.

---

## 🗑 Uninstall

### One-line uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-USB-Logs/main/uninstall.sh)"
```

### Manual uninstall

```sh
/etc/init.d/usb-log-mirror stop
/etc/init.d/usb-log-mirror disable
rm -f /etc/init.d/usb-log-mirror /usr/bin/usb-log-mirror.sh
```

> Note: Uninstall does not delete existing USB log files. Remove `/mnt/sda1/gl-usb-logs/` manually if desired.

---

## 🧾 Support-facing message (copy/paste)

"Your router still logs exactly the normal GL.iNet/OpenWrt way, so `logread` works as usual. We additionally run a small startup service that mirrors logs to USB at `/mnt/sda1/gl-usb-logs/system.log` for persistence after reboot. If USB is not ready at boot, normal logging is unaffected and the mirror starts automatically when USB becomes available."

---

## 🧩 Compatibility

- Designed for BusyBox ash / OpenWrt / GL.iNet firmware.
- Validated for GL-XE300 (Puli) use case.
- Expected USB mount pattern: `/mnt/sda1` (default), adjustable if your mount point differs.
