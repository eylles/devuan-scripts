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
        printf '\n'
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

show_usage () {
    printf '%s\n'   "Usage:"
    printf '\t%s\n' "${myname} [OPTIONS] ACTION"
}

###########
# Strings #
###########

Ustr="Update System"
Mstr="Maintain System"
Istr="Install Packages"
Pstr="Purge package"
Lstr="List package files"
Sstr="Search package files"
Qstr="Quit"
Hstr="Help"

show_help () {
    printf '%s\n' \
        "${myname} - a wrapper for apt using fzf"
    show_usage
    printf '\n%s\n' \
        "  oneshot, -o, --oneshot"
    printf '\t%s\n' \
        "perform the selected action then exit, if no action is passed the menu is"
    printf '\t%s\n' \
        "shown for the user to select an action, after the action finishes, regardless"
    printf '\t%s\n' \
        "if it was performed or cancelled ${myname} will simply exit."
    printf '\n%s\n' \
        "  1, u, update, update-system"
    printf '\t%s\n' \
        "${Ustr}, runs sudo \$aptcmd upgrade"
    printf '\n%s\n' \
        "  2, m, maintain, maintain-system"
    printf '\t%s\n' \
        "${Mstr}, uses apt-get to autoclean, autoclean and update --fix-missing"
    printf '\n%s\n' \
        "  3, i, install, install-packages"
    printf '\t%s\n' \
        "${Istr}, shows an fzf menu list of available packages to install with '\$aptcmd install'"
    printf '\n%s\n' \
        "  4, r, p, remove, purge, remove-packages-and-deps, purge-packages"
    printf '\t%s\n' \
        "${Pstr}, shows an fzf menu list of installed packages to remove with '\$aptcmd purge'"
    printf '\n%s\n' \
        "  5, l, list, list-package-files"
    printf '\t%s\n' \
        "${Lstr}, shows an fzf menu to get the list of file from a package"
    printf '\n%s\n' \
        "  6, s, search, search-package-files"
    printf '\t%s\n' \
        "${Sstr}, shows an fzf menu to query dpkg for which package provides the selected file"
}

menu () {
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
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "1" "$s1i" "$s1r"
    printf '%*s' "12" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "2" "$s2i" "$s2r"
    printf '%*s%s \n' "6" " " "│"

    printf ' %s%78s%s \n' "│" " " "│"

    s1i=$(spli "$Istr" 1); s1r=$(spli "$Istr" 2)
    s2i=$(spli "$Pstr" 1); s2r=$(spli "$Pstr" 2)
    printf ' %s      ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "3" "$s1i" "$s1r"
    printf '%*s' "12" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "4" "$s2i" "$s2r"
    printf '%*s%s \n' "6" " " "│"

    printf ' %s%78s%s \n' "│" " " "│"

    s1i=$(spli "$Lstr" 1); s1r=$(spli "$Lstr" 2)
    s2i=$(spli "$Sstr" 1); s2r=$(spli "$Sstr" 2)
    printf ' %s      ' "│"
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "5" "$s1i" "$s1r"
    printf '%*s' "12" " "
    printf '\033[7m %s \033[0m   \033[1m%s\033[0m%-20s' "6" "$s2i" "$s2r"
    printf '%*s%s \n' "6" " " "│"

    printf ' %s%78s%s \n' "│" " " "│"

    printf ' %s%s%s \n' "└" "$(mstrin "─" 78)" "┘"

    s1i=$(spli "$Qstr" 1); s1r=$(spli "$Qstr" 2)
    s2i=$(spli "$Hstr" 1); s2r=$(spli "$Hstr" 2)
    printf '\n  %s  -  \033[7m %s \033[0m \033[1m%s\033[0m%s  ' \
        "Enter number or marked letter(s)" "0" "$s1i" "$s1r"
    printf '  \033[7m %s \033[0m \033[1m%s\033[0m%s  \n' \
        "H" "$s2i" "$s2r"

    printf '\n    > '

    read -r choice
    printf '\n'
}

main () {
    oneshot=""
    out=""
    while [ -z "$out" ]; do
        choice=""

        # input parsing
        while [ "$#" -gt 0 ]; do
            case "$1" in
                oneshot|-o|--oneshot) out=1; oneshot=1 ;;
                *) choice="$1" ;;
            esac
            shift
        done

        if [ -z "$choice" ]; then
            menu
        fi

        choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]' )"

        case "$choice" in
            1|u|update|update-system)
                apt_upgrade
                pmsg "System updated. To return to ${myname} press ENTER"
                read -r _
            ;;
            2|m|maintain|maintain-system)
                apt_maintain
                pmsg "System maintenance finished. To return to ${myname} press ENTER"
                read -r _
            ;;
            3|i|install|install-packages)
                apt_install
                pmsg "Package installation finished. To return to ${myname} press ENTER"
                read -r _
            ;;
            4|r|p|remove|purge|remove-packages-and-deps|purge-packages)
                apt_purge
                pmsg "Package(s) purged. To return to ${myname} press ENTER"
                read -r _
            ;;
            5|l|list|list-package-files)
                list_pkg_files
                pmsg "Operation(s) completed. To return to ${myname} press ENTER"
                read -r _
            ;;
            6|s|search|search-package-files)
                search_pkg_by_file
                pmsg "Operation(s) completed. To return to ${myname} press ENTER"
                read -r _
            ;;
            0|q|quit|''|'\033')
                out=1
            ;;
            h|-h|help|--help)
                show_help
                if [ -z "$oneshot" ]; then
                    read -r _
                fi
            ;;
            * )
                pmsg " Wrong option $choice"
                printf '%s\n' "  Please try again...  "
                sleep 1
            ;;
        esac
    done
    [ -z "$oneshot" ] && clear
}

main "$@"
