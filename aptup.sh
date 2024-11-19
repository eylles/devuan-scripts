#!/bin/sh

myname="${0##*/}"

DBGOUT=""
DRYRUN=""
TIME=""
RAND_NUM=""
RUNSLEEP=3600

# use busybox awk whenever possible
b_awk () {
  if [ -x /usr/bin/busybox ]; then
    busybox awk "$@"
  else
    awk "$@"
  fi
}

# use busybox cat whenever possible
b_cat () {
  if [ -x /usr/bin/busybox ]; then
    busybox cat "$@"
  else
    cat "$@"
  fi
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
  RAND_NUM=$( \
    b_awk \
      -v rs="$RUNSLEEP" \
      -v s="$$""$(date +%N)" \
      'BEGIN{srand(s);print(int(rs*rand()));}' \
  )
  TIME=$(( RAND_NUM % RUNSLEEP ))
  [ "$DBGOUT" = 1 ] && printf '%s\n' "I will sleep ${TIME} seconds."
}


main () {
  slept=""
  until check_ac; do
    [ "$DBGOUT" = 1 ] && printf '%s\n' "AC not present, sleeping until it is."
    rando_time
    sleep "$TIME"
    slept=1
  done

  if [ -z "$slept" ]; then
    [ "$DBGOUT" = 1 ] && printf '%s\n' "sleeping a random amount of time"
    rando_time
    sleep "$TIME"
  fi


  if [ -z "$DRYRUN" ]; then
    /usr/bin/apt-get -q update
  fi
  [ "$DBGOUT" = 1 ] && printf '%s\n' "${myname}: update complete"
}

show_help () {
  printf '%s\n'   "${myname} - an apt daily update helper"
  printf '%s\n'   "Usage:"
  printf '\t%s\n' "${myname} help | debug | dryrun | runsleep <N>"
  printf '\n%s\n' "this script is a helper for implementing apt daily without systemd"
  printf '%s\n'   "a quick and easy way to run this script from a cronjob, either from"
  printf '%s\n'   "the root crontab or using anacron from cron.daily, this is up to you."
  printf '%s\n'   "the script will first check that the system is on ac power and then will"
  printf '%s\n'   "calculate a random time to wait between 1 second to 1 hour, if not on ac"
  printf '%s\n'   "power it will sleep a random amount of time until it is on ac power"
  printf '%s\n'   "after either case the script will update the apt package cache with"
  printf '%s\n'   "'apt-get -q update' and then terminate."
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
