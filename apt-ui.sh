#!/bin/sh

# this is a re-make of a script originally called debianUI, i could no longer find the repo where i
# got that script from, so decided to re-create it on my way as a posix shell script.

myname=${0##*/}

# Description:
#   apt-get command explicit full path
#   /usr/bin/apt-get
a_g=/usr/bin/apt-get

# Description:
#   configutable apt command
# default value: apt-get
aptcmd=$a_g

configdir="${XDG_CONFIG_HOME:-$HOME/.config}"

UserID=$(id -u)
LocalUserID=$(id -u "$(logname)")
# this could be used with sudo so we have to load the correct file
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

config="${configdir}/apt-ui/config.rc"

if [ -f "$config" ]; then
  # yep, we do NOT check the contents just source them blindly
  # if the user wrote something bad it is his problem~~
  . "$config"
fi

apt_maintain () {
  sudo $a_g autoclean
  sudo $a_g autoremove
  sudo $a_g update --fix-missing
}

apt_upgrade () {
  sudo $aptcmd upgrade
}

apt_purge () {
  pkg=""
  input=""
  pkg="$( dpkg --get-selections | grep -v deinstall | sort -k1,1 -u |
    fzf \
      -i \
      --reverse \
      --cycle --preview-window sharp \
      --prompt='filter: ' \
      --multi --exact --no-sort \
      --select-1 --margin="4%,1%,1%,2%" \
      --inline-info \
      --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
      --bind='pgdn:half-page-down,pgup:half-page-up' \
      --query="$input" \
      --preview 'apt-cache show {1} '\
      --header="TAB key to (un)select. ENTER to purge. ESC to quit." | \
    awk '{print $1}'
  )"

  pkg="$( echo "$pkg" | paste -sd " " )"
  if [ -n "$pkg" ]; then
    sudo $aptcmd purge $pkg
  fi

}

apt_install () {
  pkg=""
  input=""
  pkg="$( apt-cache search "" | sort -k1,1 -u |
    fzf \
      -i \
      --reverse \
      --cycle --preview-window sharp \
      --prompt='filter: ' \
      --multi --exact --no-sort \
      --select-1 --margin="4%,1%,1%,2%" \
      --inline-info \
      --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
      --bind='pgdn:half-page-down,pgup:half-page-up' \
      --query="$input" \
      --preview 'apt-cache show {1} '\
      --header="TAB key to (un)select. ENTER to install. ESC to quit." | \
    awk '{print $1}'
  )"

  pkg="$( printf '%s\n' "$pkg" | paste -sd " " )"
  if [ -n "$pkg" ]; then
    sudo $aptcmd install $pkg
  fi
}

# Return type: string
# Description: returns space separated list of installed packages
get_installed () {
  dpkg --get-selections | grep -v deinstall | awk '{print $1}'
}

list_pkg_files () {
  pkg=""
  input=""
  pkg="$( get_installed |
    fzf \
      -i \
      --reverse \
      --cycle --preview-window sharp \
      --prompt='filter: ' \
      --multi --exact --no-sort \
      --select-1 --margin="4%,1%,1%,2%" \
      --inline-info \
      --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
      --bind='pgdn:half-page-down,pgup:half-page-up' \
      --query="$input" \
      --preview 'dpkg -L {1} '\
      --header="TAB key to (un)select. ENTER to install. ESC to quit." | \
    awk '{print $1}'
  )"

  pkg="$( printf '%s\n' "$pkg" | paste -sd " " )"
  if [ -n "$pkg" ]; then
    dpkg -L $pkg
  fi
}

# Return type: string
# Description: returns all files from all packages separated by newline
list_all_pkg_files () {
  for package in $( get_installed ); do
    dpkg -L "$package"
  done
}

search_pkg_by_file () {
  pkg=""
  input=""
  pkg="$( list_all_pkg_files |
    fzf \
      -i \
      --reverse \
      --cycle --preview-window sharp \
      --prompt='filter: ' \
      --multi --exact --no-sort \
      --select-1 --margin="4%,1%,1%,2%" \
      --inline-info \
      --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
      --bind='pgdn:half-page-down,pgup:half-page-up' \
      --query="$input" \
      --preview 'dpkg -S {1} '\
      --header="TAB key to (un)select. ENTER to install. ESC to quit." | \
    awk '{print $1}'
  )"

  pkg="$( printf '%s\n' "$pkg" | paste -sd " " )"
  if [ -n "$pkg" ]; then
    dpkg -S $pkg
  fi
}

# Usage: mstrin "#" 5
# Output: "#####"
mstrin () {
  count=1
  strin="${1}"
  mult="${2}"
  while [ "$count" -le "$mult" ]; do
    strou="${strou}${strin}"
    count=$((count+1))
  done
  printf '%s\n' "$strou"
}

spli () {
  fchar="$(printf '%s' "$1" | cut -c 1)"
  restr="${1##$fchar}"
  case "$2" in
    1)
      out="$fchar"
      ;;
    2)
      out="$restr"
      ;;
  esac
  printf '%s\n' "$out"
}

pmsg () {
  printf ' \033[42m\033[30m %s \033[0m \n' "$@"
}

###########
# Strings #
###########

Ustr="Update System"
Mstr="Maintain System"
Istr="Install Packages"
Pstr="Purge package"
Qstr="Quit"

main () {
  out=""
  while [ -z "$out" ]; do
    clear
    printf '\n%*s \033[7m %.15s - %.15s \033[0m %*s \n' \
      "21" " " \
      "$myname" \
      "Package Manager" \
      "21" " "
    printf ' %s%s%s \n' "┌" "$(mstrin "─" 78)" "┐"

    printf ' %s%78s%s \n' "│" " " "│"

    s1i=$(spli "$Ustr" 1); s1r=$(spli "$Ustr" 2)
    s2i=$(spli "$Mstr" 1); s2r=$(spli "$Mstr" 2)
    printf ' %s      ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "1" "$s1i" "$s1r"
    printf '%*s' "22" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "2" "$s2i" "$s2r"
    printf '%*s%s \n' "6" " " "│"

    printf ' %s%78s%s \n' "│" " " "│"

    s1i=$(spli "$Istr" 1); s1r=$(spli "$Istr" 2)
    s2i=$(spli "$Pstr" 1); s2r=$(spli "$Pstr" 2)
    printf ' %s      ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "3" "$s1i" "$s1r"
    printf '%*s' "22" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "4" "$s2i" "$s2r"
    printf '%*s%s \n' "6" " " "│"

    printf ' %s%78s%s \n' "│" " " "│"

    printf ' %s%s%s \n' "└" "$(mstrin "─" 78)" "┘"

    s1i=$(spli "$Qstr" 1); s1r=$(spli "$Qstr" 2)
    printf '\n  %s  -  \033[7m %s \033[0m \033[1m%s\033[0m%s  \n' \
      "Enter number or marked letter(s)" "0" "$s1i" "$s1r"

    printf '\n    > '

    read -r choice
    choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]' )"
    printf '\n'

    case "$choice" in
      1|u|update|update-system )
        apt_upgrade
        pmsg "System updated. To return to ${myname} press ENTER"
        read -r _
        ;;
      2|m|maintain|maintain-system )
        apt_maintain
        pmsg "System maintenance finished. To return to ${myname} press ENTER"
        read -r _
        ;;
      3|i|install|install-packages )
        apt_install
        pmsg "Package installation finished. To return to ${myname} press ENTER"
        read -r _
        ;;
      4|r|remove|remove-packages-and-deps )
        apt_purge
        pmsg "Package(s) purged. To return to ${myname} press ENTER"
        read -r _
        ;;
      0|q|quit|''|'\033')
        out=1
        ;;
      * )
        pmsg " Wrong option"
        printf '%s\n' "  Please try again...  "
        sleep 1
        ;;
      esac
  done
  clear
}

main
