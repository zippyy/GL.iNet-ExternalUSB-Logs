#!/bin/sh
# usb-log-mirror.sh
# Mirror OpenWrt logread output to USB/SD storage without changing default logd behavior.

set -u

CONFIG_FILE="${USB_LOG_MIRROR_CONFIG:-/etc/usb-log-mirror.conf}"

# Defaults (can be overridden by config file or env)
USB_MOUNT="${USB_MOUNT:-/mnt/sda1}"
LOG_SUBDIR="${LOG_SUBDIR:-gl-usb-logs}"
LOG_NAME="${LOG_NAME:-system.log}"
MAX_SIZE_KB="${MAX_SIZE_KB:-5120}"
MAX_FILES="${MAX_FILES:-5}"
RETRY_SECONDS="${RETRY_SECONDS:-10}"
CHECK_EVERY_LINES="${CHECK_EVERY_LINES:-50}"
AUTO_DETECT_STORAGE="${AUTO_DETECT_STORAGE:-1}"
PREFERRED_MOUNTS="${PREFERRED_MOUNTS:-/mnt/sda1 /mnt/sdb1 /mnt/mmcblk0p1 /mnt/mmcblk1p1}"
FALLBACK_LOCAL_DIR="${FALLBACK_LOCAL_DIR:-/logs-backup}"
TAG="usb-log-mirror"

# Optional explicit paths (if set, these are respected)
LOG_DIR="${LOG_DIR:-}"
LOG_FILE="${LOG_FILE:-}"

# Load optional config file
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
fi

CUSTOM_LOG_DIR=0
CUSTOM_LOG_FILE=0
[ -n "${LOG_DIR:-}" ] && CUSTOM_LOG_DIR=1
[ -n "${LOG_FILE:-}" ] && CUSTOM_LOG_FILE=1

ACTIVE_MOUNT=""
ACTIVE_TARGET="mount"

log_msg() {
    logger -t "$TAG" "$*"
}

is_path_writable_mount() {
    path="$1"
    [ -n "$path" ] || return 1
    [ -d "$path" ] || return 1

    awk -v m="$path" '$2==m {print $4}' /proc/mounts | grep -Eq '(^|,)rw(,|$)' || return 1

    touch "$path/.usb-log-mirror-write-test" 2>/dev/null || return 1
    rm -f "$path/.usb-log-mirror-write-test" 2>/dev/null
    return 0
}

detect_storage_mount() {
    # 1) Prefer configured mount path if present and writable.
    if is_path_writable_mount "$USB_MOUNT"; then
        echo "$USB_MOUNT"
        return 0
    fi

    # 2) Optional autodetect for USB/SD paths.
    [ "$AUTO_DETECT_STORAGE" = "1" ] || return 1

    for m in $PREFERRED_MOUNTS; do
        if is_path_writable_mount "$m"; then
            echo "$m"
            return 0
        fi
    done

    # 3) Fallback: scan /proc/mounts for common block devices.
    for m in $(awk '$1 ~ /^\/dev\/(sd[a-z][0-9]*|mmcblk[0-9]+p?[0-9]*)$/ {print $2}' /proc/mounts); do
        if is_path_writable_mount "$m"; then
            echo "$m"
            return 0
        fi
    done

    return 1
}

refresh_paths() {
    root_path="$1"
    target_type="${2:-mount}"

    [ -n "$root_path" ] || return 1
    ACTIVE_TARGET="$target_type"
    [ "$target_type" = "mount" ] && USB_MOUNT="$root_path"

    if [ "$CUSTOM_LOG_DIR" -eq 0 ]; then
        LOG_DIR="$root_path/$LOG_SUBDIR"
    fi

    if [ "$CUSTOM_LOG_FILE" -eq 0 ]; then
        LOG_FILE="$LOG_DIR/$LOG_NAME"
    fi

    return 0
}

ensure_paths() {
    mkdir -p "$LOG_DIR" 2>/dev/null || return 1
    touch "$LOG_FILE" 2>/dev/null || return 1
    return 0
}

rotate_copytruncate() {
    [ -f "$LOG_FILE" ] || return 0

    size_kb=$(du -k "$LOG_FILE" 2>/dev/null | awk '{print $1}')
    [ -n "$size_kb" ] || size_kb=0

    [ "$size_kb" -lt "$MAX_SIZE_KB" ] && return 0

    i="$MAX_FILES"
    while [ "$i" -gt 1 ]; do
        prev=$((i - 1))
        [ -f "$LOG_FILE.$prev" ] && mv -f "$LOG_FILE.$prev" "$LOG_FILE.$i"
        i=$prev
    done

    cp "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null || return 1
    : > "$LOG_FILE" 2>/dev/null || return 1
    log_msg "rotated $LOG_FILE at ${size_kb}KB (max=${MAX_SIZE_KB}KB files=${MAX_FILES})"
    return 0
}

stream_logs() {
    line_count=0
    log_msg "stream start -> $LOG_FILE"

    logread -f 2>/dev/null | while IFS= read -r line; do
        printf '%s\n' "$line" >> "$LOG_FILE" || exit 1
        line_count=$((line_count + 1))

        if [ $((line_count % CHECK_EVERY_LINES)) -eq 0 ]; then
            rotate_copytruncate || true
        fi
    done

    rc=$?
    log_msg "stream ended rc=$rc"
    return "$rc"
}

daemon() {
    log_msg "daemon start (configured USB_MOUNT=$USB_MOUNT fallback=$FALLBACK_LOCAL_DIR)"

    while true; do
        detected_mount=$(detect_storage_mount || true)
        target_key="$detected_mount"
        target_type="mount"
        target_root="$detected_mount"

        if [ -z "$target_root" ]; then
            target_key="local:$FALLBACK_LOCAL_DIR"
            target_type="local"
            target_root="$FALLBACK_LOCAL_DIR"
        fi

        if [ "$target_key" != "$ACTIVE_MOUNT" ]; then
            refresh_paths "$target_root" "$target_type" || true
            ACTIVE_MOUNT="$target_key"
            log_msg "using $target_type target: $target_root (log: $LOG_FILE)"
        fi

        if ! ensure_paths; then
            log_msg "unable to access $LOG_FILE"
            sleep "$RETRY_SECONDS"
            continue
        fi

        rotate_copytruncate || true
        stream_logs
        sleep 2
    done
}

case "${1:-}" in
    daemon)
        daemon
        ;;
    rotate)
        detected_mount=$(detect_storage_mount || true)
        if [ -n "$detected_mount" ]; then
            refresh_paths "$detected_mount" "mount"
        else
            refresh_paths "$FALLBACK_LOCAL_DIR" "local"
        fi
        ensure_paths || exit 1
        rotate_copytruncate
        ;;
    check)
        detected_mount=$(detect_storage_mount || true)
        if [ -n "$detected_mount" ]; then
            refresh_paths "$detected_mount" "mount"
            if ensure_paths; then
                echo "ok: $detected_mount"
                exit 0
            fi
        fi
        refresh_paths "$FALLBACK_LOCAL_DIR" "local"
        if ensure_paths; then
            echo "ok-local: $FALLBACK_LOCAL_DIR"
            exit 0
        fi
        echo "not-ready"
        exit 1
        ;;
    *)
        echo "Usage: $0 {daemon|rotate|check}" >&2
        exit 1
        ;;
esac