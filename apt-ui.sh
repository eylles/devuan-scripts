#!/bin/sh

myname=${0##*/}

aptcmd=apt-get

apt_maintain () {
  sudo apt-get autoclean
  sudo apt-get autoremove
  sudo apt-get update --fix-missing
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
      --preview-window=right:55%:wrap \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
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
      --preview-window=right:55%:wrap \
      --bind alt-k:preview-up \
      --bind alt-j:preview-down \
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
    printf '%*s \033[7m %.15s - %.15s \033[0m %*s \n' \
      "21" " " \
      "$myname" \
      "Package Manager" \
      "21" " "
    printf ' %s%s%s \n' "┌" "$(mstrin "─" 78)" "┐"

    s1i=$(spli "$Ustr" 1); s1r=$(spli "$Ustr" 2)
    s2i=$(spli "$Mstr" 1); s2r=$(spli "$Mstr" 2)
    printf ' %s    ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "1" "$s1i" "$s1r"
    printf '%*s' "22" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "2" "$s2i" "$s2r"
    printf '%*s%s \n' "8" " " "│"

    s1i=$(spli "$Istr" 1); s1r=$(spli "$Istr" 2)
    s2i=$(spli "$Pstr" 1); s2r=$(spli "$Pstr" 2)
    printf ' %s    ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "3" "$s1i" "$s1r"
    printf '%*s' "22" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-15s' "4" "$s2i" "$s2r"
    printf '%*s%s \n' "8" " " "│"

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
        sleep 2
        ;;
      esac
  done
  clear
}

main
