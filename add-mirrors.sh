#!/bin/sh

myname=${0##*/}

# Return type: string
# Usage: trim_string "   example   string    "
# Out:   "example   string"
trim_string() {
    # Remove all leading white-space.
    # '${1%%[![:space:]]*}': Strip everything but leading white-space.
    # '${1#${XXX}}': Remove the white-space from the start of the string.
    trim=${1#${1%%[![:space:]]*}}

    # Remove all trailing white-space.
    # '${trim##*[![:space:]]}': Strip everything but trailing white-space.
    # '${trim%${XXX}}': Remove the white-space from the end of the string.
    trim=${trim%${trim##*[![:space:]]}}

    printf '%s\n' "$trim"
}

# Usage: lwc "EXAMPLE String"
# Out:   "example string"
lwc () {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
}

b_spacer="#################"
b_middle="###################"
distro_str_D=" Distribution Info "
distro_str_t="Type"
distro_str_d="Description"
distro_type=$(lsb_release -i)
distro_type="${distro_type##*:}"
distro_type=$(trim_string "$distro_type")
distro_type=$(lwc "$distro_type")
distro_name=$(lsb_release -d)
distro_name="${distro_name##*:}"
distro_name=$(trim_string "$distro_name")

distro_info () {
    # print distro info
    printf '%s%s%s\n'   "$b_spacer" "$distro_str_D" "$b_spacer"
    printf '# %11s: %-36s #\n' "$distro_str_t" "$distro_type"
    printf '# %11s: %-36s #\n' "$distro_str_d" "$distro_name"
    printf '%s%s%s\n'   "$b_spacer" "$b_middle" "$b_spacer"
    printf '\n'
}

######################
# devuan suite names #
######################

dev_otab=daedalus
dev_stab=excalibur
dev_test=freia
dev_unst=ceres


######################
# debian suite names #
######################

deb_otab=bookworm
deb_stab=trixie
deb_test=forky
deb_unst=sid

######################
# mirror urls to use #
######################

# devuan
dev_urls=""
dev_urls="${dev_urls} deb.devuan.nz"
dev_urls="${dev_urls} deb.devuan.org"

# debian
deb_urls=""
deb_urls="${deb_urls} ftp.nz.debian.org"
deb_urls="${deb_urls} deb.debian.org"

# mirror name urls, ie: deb.debian.org
urls=""
# archive type, "debian" for debian and "merged" for devuan
archive=""
# old-stable suite, ie bookworm or daedalus
u_otab=""
# stable suite, ie bookworm or daedalus
u_stab=""
# testing suite, ie trixie or excalibur
u_test=""
# unstable suite, ie sid or ceres
u_unst=""

case "${distro_type}" in
    debian)
        urls=${deb_urls}
        archive="debian"
        u_otab="$deb_otab"
        u_stab="$deb_stab"
        u_test="$deb_test"
        u_unst="$deb_unst"
    ;;
    devuan)
        urls=${dev_urls}
        archive="merged"
        u_otab="$dev_otab"
        u_stab="$dev_stab"
        u_test="$dev_test"
        u_unst="$dev_unst"
    ;;
esac

# Usage: printurl "domain" "suite" "suffix"
# Examples:
#   domain: deb.debian.org
#   suite:  bookworm
#   suffix: backports
printurl () {
    # domain
    d="${1}"
    # suite
    s="${2}"
    # suffix
    u=""
    if [ -n "${3}" ]; then
        u="-${3}"
    fi
    printf '%s\n'     "deb http://${d}/${archive} ${s}${u} main contrib non-free non-free-firmware"
    printf '%s\n' "deb-src http://${d}/${archive} ${s}${u} main contrib non-free non-free-firmware"
    printf '\n'
}

# Usage: print_deb_url "$mirror" "$suite"
# Suite: stable, testing, unstable
# Mirror: deb mirror url like: deb.devuan.org
print_deb_url () {
    case ${2} in
        unstable)
            printf '%s\n' "# mirror ${1}"
            printurl "${1}" "${u_unst}"
        ;;
        testing)
            printf '%s\n' "# mirror ${1}"
            printurl "${1}" "${u_test}"
        ;;
        stable)
            printf '%s\n' "# mirror ${1}"
            printurl "${1}" "${u_stab}"
            printurl "${1}" "${u_stab}" "security"
            printurl "${1}" "${u_stab}" "updates"
            printurl "${1}" "${u_stab}" "proposed-updates"
            printurl "${1}" "${u_stab}" "backports"
        ;;
        old-stable)
            printf '%s\n' "# mirror ${1}"
            printurl "${1}" "${u_otab}"
            printurl "${1}" "${u_otab}" "security"
            printurl "${1}" "${u_otab}" "updates"
            printurl "${1}" "${u_otab}" "backports"
        ;;
    esac
}

# Usage: apt_sources "suite"
# Suite: old-stable, stable, testing, unstable
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
        old-stable)
            suite=old-stable
        ;;
    esac
    echo "############################"
    printf '# %s %9s %s #\n' "${distro_type}" "${suite}" "sources"
    echo "############################"
    echo
    for mirror in ${urls}; do
        print_deb_url "$mirror" "$suite"
    done
}

show_usage () {
    printf '%s\n'   "Usage:"
    printf '\t%s\n' "${myname} [SUITE] | debug [SUITE] | help"
}

# Usage: show_help
show_help () {
    printf '%s\n'   "${myname}: add more mirrors to your devuan or debian install"
    show_usage
    printf '%s\n'   "[SUITE]:"
    printf '\t%s\n' "the standard debian suites stable, testing and unstable are supported"
    printf '\t%s\n' "as arguments as well as the debian and devuan specific codenames for"
    printf '\t%s\n' "such suites can be used without any issue."
    printf '\t%s\n' "Note however that the actual suite name written to the mirros at"
    printf '\t%s\n' "/etc/apt/sources.list WILL be the current codenames as defined"
    printf '\t%s\n' "by the script's internal variables, which are:"
    printf '\t%s\n' "for devuan:"
    printf '\t\t%s\n' "\$dev_otab: ${dev_otab}"
    printf '\t\t%s\n' "\$dev_stab: ${dev_stab}"
    printf '\t\t%s\n' "\$dev_test: ${dev_test}"
    printf '\t\t%s\n' "\$dev_unst: ${dev_unst}"
    printf '\t%s\n' "for debian:"
    printf '\t\t%s\n' "\$deb_otab: ${deb_otab}"
    printf '\t\t%s\n' "\$deb_stab: ${deb_stab}"
    printf '\t\t%s\n' "\$deb_test: ${deb_test}"
    printf '\t\t%s\n' "\$deb_unst: ${deb_unst}"
    printf '\n'
    printf '\t%s\n' "by default only 2 repos are added:"
    printf '\t%s\n' "for devuan: deb.devuan.nz and deb.devuan.org"
    printf '\t%s\n' "for debian: ftp.nz.debian.org and deb.devuan.org"
    printf '\t%s\n' "to add more repos create a file in \$XDG_CONFIG_HOME/${distro_type}/mirrors"
    printf '\t%s\n' "and inside specify your mirror's URL only in the format:"
    printf '\t\t%s\n' "urls=\"\${urls} deb.devuan.org\""
    printf '\t%s\n' "this way the script can simply append your configured mirror urls to"
    printf '\t%s\n' "the default ones."
}

# Return type: shell boolean from grep
# Usage: is_usrmerge_installed
is_usrmerge_installed () {
    dpkg -l usrmerge | grep -q '^ii'
}

# Type: int
# value: 0
btrue=0
# Type: int
# value: 1
bfalse=1

# Return type: shell boolean
# Usage: is_old_stable "suite"
is_old_stable () {
    retval=$bfalse
    case "$1" in
        old-stable)
            retval=$btrue
            ;;
    esac
    return $retval
}

# Usage: set_mirrors "suite"
# Suite: old-stable, stable, testing, unstable
set_mirrors () {
    distro_info
    if ! is_old_stable "$1" && ! is_usrmerge_installed; then
        apt install usrmerge
    fi
    mv /etc/apt/sources.list /etc/apt/sources.list.stable.bak
    apt_sources "$1" > /etc/apt/sources.list
    apt update
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

usemirrors="${configdir}/${distro_type}/mirrors"

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
                    distro_info
                    echo "the following settings will be applied:"
                    printf '%s\n' "apt: install usrmerge"
                    printf '%s\n' "apt sources: ${2} suite"
                    apt_sources "unstable"
                ;;
                testing|"${deb_test}"|"${dev_test}")
                    distro_info
                    echo "the following settings will be applied:"
                    printf '%s\n' "apt: install usrmerge"
                    printf '%s\n' "apt sources: ${2} suite"
                    apt_sources "testing"
                ;;
                stable|"${deb_stab}"|"${dev_stab}")
                    distro_info
                    echo "the following settings will be applied:"
                    printf '%s\n' "apt: install usrmerge"
                    printf '%s\n' "apt sources: ${2} suite"
                    apt_sources "stable"
                ;;
                old-stable|"${deb_otab}"|"${dev_otab}")
                    distro_info
                    echo "the following settings will be applied:"
                    printf '%s\n' "apt sources: ${2} suite"
                    apt_sources "old-stable"
                ;;
                *)
                    printf '%s' "no valid suite chosen, choose from the current"
                    printf '%s\n' "stable, testing or unstable suites!"
                    show_help
                    exit 1
                ;;
            esac
        else
            echo "no suite chosen! choose a suite!"
            show_usage
            exit 1
        fi
    ;;
    unstable|"${deb_unst}"|"${dev_unst}")
        set_mirrors "unstable"
    ;;
    testing|"${deb_test}"|"${dev_test}")
        set_mirrors "testing"
    ;;
    stable|"${deb_stab}"|"${dev_stab}")
        set_mirrors "stable"
    ;;
    old-stable|"${deb_otab}"|"${dev_otab}")
        set_mirrors "old-stable"
    ;;
    -h|-help|--help|help)
        show_help
    ;;
    *)
        echo "no option chosen, send debug or suite (stable, testing, unstable)."
        echo "check the help section with either 'help' '-h' '--help' '-help'"
        show_usage
        exit 1
    ;;
esac
