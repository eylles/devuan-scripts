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


# input parsing
while [ "$#" -gt 0 ]; do
  case "$1" in
    debug)   DBGOUT=1  ;;
    dryrun)  DRYRUN=1  ;;
    runsleep)
      shift
      RUNSLEEP="$1"
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
