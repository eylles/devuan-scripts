#!/bin/sh

myname="${0##*/}"

# To find which FS support trim, we check that DISC-MAX (discard max bytes)
# is great than zero. Check discard_max_bytes documentation at
# https://www.kernel.org/doc/Documentation/block/queue-sysfs.txt

PATH=/usr/sbin:/usr/bin:/sbin:/bin

progressbar_process_wait_spinner() {
    count=0
    spinSymbol=0
    progressBarPrefix="$2"
    steptime=0.1
    watchPID="$1"

    while kill -0 "$watchPID" 2>/dev/null; do
        case "$spinSymbol" in
            0) spin="-" ;;
            1) spin="\\" ;;
            2) spin="|" ;;
            3) spin="/" ;;
        esac
        printf ' %s%s\r' "$progressBarPrefix" "[$spin]"
        sleep "$steptime"
        count=$(( count + 1 ))
        spinSymbol=$(( spinSymbol + 1 ))
        [ "$spinSymbol" -gt 3 ] && spinSymbol=0
    done
    printf '  %s%s\r' "$progressBarPrefix" "   "
    sleep 0.1
    printf '\n'
}

# usage: msg_log "level" "message"
# log message
msg_log () {
    loglevel="$1"
    shift
    message="$*"
    logger -i -t "$myname" -p "cron.${loglevel}" "$message"
}

# use busybox awk whenever possible
b_awk () {
    if [ -x /usr/bin/busybox ]; then
        busybox awk "$@"
    else
        awk "$@"
    fi
}

# use busybox grep whenever possible
b_grep () {
    if [ -x /usr/bin/busybox ]; then
        busybox grep "$@"
    else
        grep "$@"
    fi
}

get_trimable_fs () {
    lsblk -o MOUNTPOINT,DISC-MAX,FSTYPE | \
        b_grep -E '^/.* [1-9]+.* ' | \
        b_awk '{print $1}'
}

for fs in $(get_trimable_fs); do
    [ -z "$1" ] || printf '%s\n' "sending trim to $fs"
    if [ -z "$1" ]; then
        msg_log "info" "initiating fstrim on $fs"
        fstrim "$fs"
    else
        fstrim "$fs" &
    fi
    [ -z "$1" ] || progressbar_process_wait_spinner $! "waiting for fstrim on: $fs  "
done
