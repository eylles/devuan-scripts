#!/bin/sh

list_apt_upgradeable () {
    apt list --upgradable 2>/dev/null | sed '/^Listing.../d; s/,[^ ]*//' | column -t
}

show_header () {
    printf '%*s%s\n' 38 " " "# Upgradeable Packages #"
}

out_comb () {
    if [ -x "$(command -v awkat)" ]; then
        list_apt_upgradeable | awkat -I "apt" -N "Upgradeable Packages"
    else
        show_header
        list_apt_upgradeable
    fi
}

out_comb | less
