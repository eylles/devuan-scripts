#!/bin/sh

myname=${0##*/}

######################
# devuan suite names #
######################

dev_stab=daedalus
dev_test=excalibur
dev_unst=ceres


######################
# debian suite names #
######################

deb_stab=bookworm
deb_test=trixie
deb_unst=sid

# mirror urls to use
deb_urls=""
deb_urls="${deb_urls} deb.devuan.nz"
deb_urls="${deb_urls} deb.devuan.org"

print_deb_url () {
  case ${2} in
    unstable)
      printf '%s\n' "# mirror ${1}"
      printf '%s\n'     "deb http://${1}/merged ${dev_unst} main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_unst} main contrib non-free non-free-firmware"
      printf '\n'
      ;;
    testing)
      printf '%s\n' "# mirror ${1}"
      printf '%s\n'     "deb http://${1}/merged ${dev_test} main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_test} main contrib non-free non-free-firmware"
      printf '\n'
      ;;
    stable)
      printf '%s\n' "# mirror ${1}"
      printf '%s\n'     "deb http://${1}/merged ${dev_stab} main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_stab} main contrib non-free non-free-firmware"
      printf '\n'
      printf '%s\n'     "deb http://${1}/merged ${dev_stab}-security main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_stab}-security main contrib non-free non-free-firmware"
      printf '\n'
      printf '%s\n'     "deb http://${1}/merged ${dev_stab}-updates main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_stab}-updates main contrib non-free non-free-firmware"
      printf '\n'
      printf '%s\n'     "deb http://${1}/merged ${dev_stab}-backports main contrib non-free non-free-firmware"
      printf '%s\n' "deb-src http://${1}/merged ${dev_stab}-backports main contrib non-free non-free-firmware"
      printf '\n'
      ;;
  esac
}

apt_sources () {
  case ${1} in
    unstable)
      suite=unstable
      ;;
    testing)
      suite=testing
      ;;
    stable)
      suite=stable
      ;;
  esac
  echo "############################"
  printf '%s %9s %s\n' "# devuan" "${suite}" "sources #"
  echo "############################"
  echo
  for mirror in ${deb_urls}; do
    print_deb_url "$mirror" "$suite"
  done
}

configdir="${XDG_CONFIG_HOME:-$HOME/.config}"

UserID=$(id -u)
LocalUserID=$(id -u "$(logname)")
# this will usually be used with sudo so we have to load the correct file
if [ "$UserID" -eq 0 ]; then
  # seems we are root
  # are we really root tho?
  if [ "$UserID" -ne "$LocalUserID" ]; then
    # not actual root
    # get local user name
    user=$(logname)
    # if this is not your actual config dir then get rekt
    configdir="/home/${user}/.config"
  fi
fi

usemirrors="${configdir}/devuan/mirrors"

if [ -f "$usemirrors" ]; then
  # yep, we do NOT check the contents just source them blindly
  # if the user wrote something bad it is his problem~~
  . "$usemirrors"
fi

case ${1} in
  debug)
    if [ -n "${2}" ]; then
      case ${2} in
        unstable|"${deb_unst}"|"${dev_unst}")
          echo "the following settings will be applied:"
          printf '%s\n' "apt: install usrmerge"
          printf '%s\n' "apt sources: ${2} suite"
          apt_sources "unstable"
          ;;
        testing|"${deb_test}"|"${dev_test}")
          echo "the following settings will be applied:"
          printf '%s\n' "apt: install usrmerge"
          printf '%s\n' "apt sources: ${2} suite"
          apt_sources "testing"
          ;;
        stable|"${deb_stab}"|"${dev_stab}")
          echo "the following settings will be applied:"
          printf '%s\n' "apt sources: ${2} suite"
          apt_sources "stable"
          ;;
        *)
          printf '%s' "no valid suite chosen, choose from the current"
          printf '%s\n' "stable, testing or unstable suites!"
          ;;
      esac
    else
      echo "no suite chosen! choose a suite!"
      exit 1
    fi
    ;;
  unstable|"${deb_unst}"|"${dev_unst}")
    apt install usrmerge
    mv /etc/apt/sources.list /etc/apt/sources.list.stable.bak
    apt_sources "sid" > /etc/apt/sources.list
    apt update
    ;;
  testing|"${deb_test}"|"${dev_test}")
    apt install usrmerge
    mv /etc/apt/sources.list /etc/apt/sources.list.stable.bak
    apt_sources "testing" > /etc/apt/sources.list
    apt update
    ;;
  stable|"${deb_stab}"|"${dev_stab}")
    mv /etc/apt/sources.list /etc/apt/sources.list.stable.bak
    apt_sources "stable" > /etc/apt/sources.list
    apt update
    ;;
  -h|-help|--help|help)
    printf '%s\n'   "${myname}: add more mirrors to your devuan install"
    printf '%s\n'   "Usage:"
    printf '\t%s\n' "${myname} [SUITE] | debug [SUITE] | help"
    printf '%s\n'   "[SUITE]:"
    printf '\t%s\n' "the standard debian suites stable, testing and unstable are supported"
    printf '\t%s\n' "as arguments as well as the debian and devuan specific codenames for"
    printf '\t%s\n' "such suites can be used without any issue."
    printf '\t%s\n' "Note however that the actual suite name written to the mirros at"
    printf '\t%s\n' "/etc/apt/sources.list WILL be the current DEVUAN codenames as defined"
    printf '\t%s\n' "by the script's internal variables, which are:"
    printf '\t\t%s\n' "\$dev_stab: ${dev_stab}"
    printf '\t\t%s\n' "\$dev_test: ${dev_test}"
    printf '\t\t%s\n' "\$dev_unst: ${dev_unst}"
    printf '\n'
    printf '\t%s\n' "by default only the repos added are deb.devuan.nz and deb.devuan.org"
    printf '\t%s\n' "to add more repos create a file in \$XDG_CONFIG_HOME/devuan/mirrors"
    printf '\t%s\n' "and inside specify your mirror's URL only in the format:"
    printf '\t\t%s\n' "deb_urls=\"\${deb_urls} deb.devuan.org\""
    printf '\t%s\n' "this way the script can simply append your configured mirror urls to"
    printf '\t%s\n' "the default ones."
    ;;
  *)
    echo "no option chosen, send debug or suite (stable, testing, unstable)."
    echo "check the help section with either 'help' '-h' '--help' '-help'"
    exit 1
   ;;
esac


