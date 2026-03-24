#!/bin/sh
# usb-log-mirror.sh
# Mirrors OpenWrt logread output to USB storage without changing logd defaults.

USB_MOUNT="${USB_MOUNT:-/mnt/sda1}"
LOG_DIR="${LOG_DIR:-$USB_MOUNT/gl-usb-logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/system.log}"
MAX_SIZE_KB="${MAX_SIZE_KB:-5120}"   # 5 MiB
MAX_FILES="${MAX_FILES:-5}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}" # seconds

log_msg() {
    logger -t usb-log-mirror "$*"
}

is_usb_ready() {
    [ -d "$USB_MOUNT" ] || return 1
    mount | grep -q "on $USB_MOUNT " || return 1
    touch "$USB_MOUNT/.usb-log-mirror-write-test" 2>/dev/null || return 1
    rm -f "$USB_MOUNT/.usb-log-mirror-write-test" 2>/dev/null
    return 0
}

rotate_logs() {
    [ -f "$LOG_FILE" ] || return 0

    size_kb=$(du -k "$LOG_FILE" 2>/dev/null | awk '{print $1}')
    [ -n "$size_kb" ] || size_kb=0

    [ "$size_kb" -lt "$MAX_SIZE_KB" ] && return 0

    i=$MAX_FILES
    while [ "$i" -gt 1 ]; do
        prev=$((i - 1))
        [ -f "$LOG_FILE.$prev" ] && mv -f "$LOG_FILE.$prev" "$LOG_FILE.$i"
        i=$prev
    done

    mv -f "$LOG_FILE" "$LOG_FILE.1"
    : > "$LOG_FILE"
    log_msg "rotated $LOG_FILE at ${size_kb}KB"
}

ensure_log_dir() {
    mkdir -p "$LOG_DIR" || return 1
    touch "$LOG_FILE" || return 1
    return 0
}

run_mirror() {
    # Use line-buffered append stream from ring buffer updates.
    log_msg "starting log stream to $LOG_FILE"
    logread -f >> "$LOG_FILE" 2>/dev/null
    rc=$?
    log_msg "logread exited with rc=$rc; restarting"
    return "$rc"
}

daemon_loop() {
    log_msg "daemon started (USB_MOUNT=$USB_MOUNT LOG_FILE=$LOG_FILE)"

    last_rotate_check=0
    while true; do
        if ! is_usb_ready; then
            sleep 10
            continue
        fi

        if ! ensure_log_dir; then
            log_msg "cannot create log dir/file under $LOG_DIR"
            sleep 10
            continue
        fi

        now=$(date +%s 2>/dev/null)
        [ -n "$now" ] || now=0
        if [ $((now - last_rotate_check)) -ge "$CHECK_INTERVAL" ]; then
            rotate_logs
            last_rotate_check=$now
        fi

        run_mirror
        sleep 2
    done
}

case "$1" in
    daemon)
        daemon_loop
        ;;
    rotate)
        rotate_logs
        ;;
    *)
        echo "Usage: $0 {daemon|rotate}"
        exit 1
        ;;
esac
