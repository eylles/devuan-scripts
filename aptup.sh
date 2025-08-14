#!/bin/sh

myname="${0##*/}"

DBGOUT=""
DRYRUN=""
TIME=""
RAND_NUM=""
# Hour Seconds
H_S=3600
def_SfH=3
# Sleep for Hours, by default 3 hours
SfH=""

CONFIG="/etc/apt/aptup.conf"

# Usage: getval "KEY" file default
# Return: string
# Description:
#   Read a KEY=VALUE file and retrieve the Value of the passed KEY
getval(){
  # Setting 'IFS' tells 'read' where to split the string.
  while IFS='=' read -r key val; do
    # Skip over lines containing comments.
    # (Lines starting with '#').
    [ "${key##\#*}" ] || continue

    # '$key' stores the key.
    # '$val' stores the value.
    if [ "$key" = "$1" ]; then
      printf '%s\n' "$val"
    fi
  done < "$2"
}

# return type: boolean
# usage: is_num "value"
# description: check if passed value is a number
is_num() {
    printf %f "$1" >/dev/null 2>&1
}

if [ -r "$CONFIG" ]; then
    SfH=$(getval "SLEEP_FOR_HOURS" "$CONFIG")
    if ! is_num "$SfH"; then
        SfH=""
    fi
fi

if [ -z "$SfH" ]; then
    SfH="$def_SfH"
fi

# use busybox awk whenever possible
b_awk () {
    if [ -x /usr/bin/busybox ]; then
        busybox awk "$@"
    else
        awk "$@"
    fi
}

RUNSLEEP=$(b_awk -v sec="$H_S" -v hour="$SfH" 'BEGIN {printf "%d\n", sec*hour}')

# use busybox cat whenever possible
b_cat () {
    if [ -x /usr/bin/busybox ]; then
        busybox cat "$@"
    else
        cat "$@"
    fi
}

has_tty=""
if tty | grep -qF -e "dev/tty" -e "dev/pts"; then
    has_tty=1
fi

# usage: msg_log "level" "message"
# log message
msg_log () {
    loglevel="$1"
    shift
    message="$*"
    logger -i -t "$myname" -p "cron.${loglevel}" "$message"
}

# check if we are on ac power
# return type: int
# return:
#   0: we are on AC.
#   1: we aren't.
check_ac () {
    retval=1

    if [ ! -f /sys/class/power_supply/AC/online ]; then
        # the power supply class AC is not defined, thus we should be on a desktop system
        retval=0
        [ "$DBGOUT" = 1 ] && printf '%s\n' "running on desktop mode"
    else
        # so we got a power supply class, are we on battery?
        ac_state=$(b_cat /sys/class/power_supply/AC/online)
        case "$ac_state" in
            0)
                [ "$DBGOUT" = 1 ] && printf '%s\n' "we are on battery"
                retval=1
            ;;
            1)
                [ "$DBGOUT" = 1 ] && printf '%s\n' "we are on AC"
                retval=0
            ;;
        esac
    fi

    return "$retval"
}

rando_time () {
    sleep_truncater="$RUNSLEEP"
    if [ -n "$1" ]; then
        sleep_truncater="$1"
    fi
    RAND_NUM=$( \
        b_awk \
            -v rs="$RUNSLEEP" \
            -v s="$$""$(date +%N)" \
            'BEGIN{srand(s);print(int(rs*rand()));}' \
    )
    TIME=$(( RAND_NUM % sleep_truncater ))
    if [ "$DBGOUT" = 1 ] || [ "$has_tty" = 1 ]; then
        printf '%s\n' "I will sleep ${TIME} seconds."
    fi
}

do_sleep () {
    if [ -z "$DRYRUN" ]; then
        sleep "$TIME"
    else
        sleep 2
    fi
}


main () {
    slept=""
    until check_ac; do
        if [ "$DBGOUT" = 1 ] || [ "$has_tty" = 1 ]; then
            printf '%s\n' "AC not present, sleeping until it is."
        fi
        rando_time 1800
        do_sleep "$TIME"
        slept=1
    done

    if [ -z "$slept" ]; then
        if [ "$DBGOUT" = 1 ] || [ "$has_tty" = 1 ]; then
            printf '%s\n' "sleeping a random amount of time"
        fi
        rando_time
        do_sleep "$TIME"
    fi


    if [ -z "$DRYRUN" ]; then
        /usr/bin/apt-get -q update
        msg_log "info" "package index update completed"
    fi
    if [ "$DBGOUT" = 1 ] || [ "$has_tty" = 1 ]; then
        printf '%s\n' "${myname}: update complete"
    fi
}

show_help () {
    printf '%s\n'   "${myname} - an apt daily update helper"
    printf '%s\n'   "Usage:"
    printf '\t%s\n' "${myname} help | debug | dryrun | runsleep <N>"
    printf '\n%s\n' "this script is a helper for implementing apt daily without systemd"
    printf '%s\n'   "a quick and easy way to run this script from a cronjob, either from"
    printf '%s\n'   "the root crontab or using anacron from cron.daily, this is up to you."
    printf '%s\n'   "the script will first check that the system is on ac power and then will"
    printf '%s\n'   "calculate a random time to wait between 1 second to ${SfH} hours, if not on ac"
    printf '%s\n'   "power it will sleep a random amount of time (between one second and half hour)"
    printf '%s\n'   "until it is on ac power."
    printf '%s\n'   "after either case the script will update the apt package cache with"
    printf '%s\n'   "'apt-get -q update' and then terminate."
    printf '\n%s\n' "CONFIG"
    printf '%s\n'   "the config file is to be located at '$CONFIG' as a key=val file"
    printf '%s\n'   "that contains the SLEEP_FOR_HOURS key and admits a FLOAT value for defining"
    printf '%s\n'   "the maximum amount of hours to sleep before updating the apt index."
}

# input parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        debug|-d|--debug)   DBGOUT=1  ;;
        dryrun|-n|--dry-run)  DRYRUN=1  ;;
        runsleep|-r)
            shift
            RUNSLEEP="$1"
        ;;
        help|-h|--help)
            show_help
            exit 0
        ;;
        *)
            printf '%s\n' "${myname}: error, invalid argument: ${1}"
            exit 1
        ;;
    esac
    shift
done

[ "$DBGOUT" = 1 ] && printf '%s\n' "${myname}"

main
