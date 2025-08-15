#!/bin/sh

myname="${0##*/}"

# To find which FS support trim, we check that DISC-MAX (discard max bytes)
# is great than zero. Check discard_max_bytes documentation at
# https://www.kernel.org/doc/Documentation/block/queue-sysfs.txt

PATH=/usr/sbin:/usr/bin:/sbin:/bin

DRYRUN=""
INTERACTIVE=""

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

do_trim () {
    if [ -z "$DRYRUN" ]; then
        fstrim "$1"
    fi
}

trim_every_fs () {
    for fs in $(get_trimable_fs); do
        [ -n "$INTERACTIVE" ] && printf '%s\n' "sending trim to $fs"
        if [ -z "$INTERACTIVE" ]; then
            msg_log "info" "initiating fstrim on $fs"
            do_trim "$fs"
        else
            do_trim "$fs" &
            progressbar_process_wait_spinner $! "waiting for fstrim on: $fs  "
        fi
    done
}

if [ "$#" -gt 0 ]; then
    INTERACTIVE=1
fi

# input parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        dryrun|-n|--dry-run)  DRYRUN=1  ;;
        i|interactive|-i)
            : # nothing to do, interactive mode already enabled
            ;;
        *)
            printf '%s\n' "${myname}: error, invalid argument: ${1}"
            exit 1
        ;;
    esac
    shift
done

trim_every_fs
