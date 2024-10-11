#!/bin/sh

myname=${0##*/}

packages="
accountsservice
network-manager
lm-sensors
fancontrol
acpi
acpitool
acpid
acpi-call-dkms
pipewire
pipewire-pulse
pipewire-jack
pipewire-alsa
pipewire-audio
wireplumber
poppler-utils
atool
xorg
xserver-xorg-video-amdgpu
xserver-xorg-video-ati
xserver-xorg-video-radeon
xserver-xorg-input-libinput
xserver-xorg-input-wacom
linux-image-amd64
linux-headers-amd64
"

graphics_drivers="
firmware-linux
firmware-linux-nonfree
firmware-amd-graphics
firmware-misc-nonfree
libglx-mesa0
libegl-mesa0
libgl1-mesa-dri
libdrm-radeon1
libdrm-amdgpu1
libdrm2
libdrm-amdgpu1
libdrm-common
libdrm2
libegl-mesa0
libegl1-mesa
libgbm1
libgl1-mesa-dri
libglapi-mesa
libglx-mesa0
libvulkan1
libx11-xcb1
libxatracker2
mesa-vulkan-drivers
mesa-vdpau-drivers
mesa-va-drivers
mesa-utils
"

devuan_base="
elogind
eudev
seatd
lsb-base
"

other="
upower
pkexec
btrfs-progs
"

flatpak="
flatpak
"

vifm="
trash-cli
dosfstools
ueberzug
vifm
"

zsh="
bash-completion
zsh
zsh-autosuggestions
zsh-syntax-highlighting
"

compression="
zstd
archivemount
7zip
p7zip-full
bzip2
rar
unar
unrar
"

downloading="
curl
aria2
wget
megatools
yt-dlp
gallery-dl
"

min_setup="
gtk3-nocsd
gtk2-engines-murrine
reportbug-gtk
yad
qt5ct
qt5-style-kvantum
gparted
arandr
brightnessctl
libnotify-bin
inotify-tools
fonts-ibm-plex
fonts-noto
fonts-noto-color-emoji
papirus-icon-theme
mpv
mpv-mpris
playerctl
nsxiv
picom
rofi
policykit-1-gnome
gnome-keyring
pulseaudio-utils
awesome
awesome-extra
copyq
copyq-plugins
flameshot
xinput
xclip
xcape
xterm
xsettingsd
xsecurelock
xss-lock
xsct
python3-dbus
zathura
zathura-pdf-poppler
network-manager-gnome
"

console_prod="
python3-pip
python3-venv
python3-build
build-essential
netcat-openbsd
inxi
ffmpeg
neofetch
neovim
mediainfo
python3-pynvim
calcurse
w3m
shellcheck
tmux
git
python3-libtmux
btop
fzf
imagemagick
highlight
psmisc
jq
ncdu
"

printing="
cups
hplip
hplip-gui
simple-scan
printer-driver-hpcups
printer-driver-hpijs
printer-driver-postscript-hp
system-config-printer
"

# Usage: _help
_help () {
  printf '%s\n'   "${myname}: quickly install or reinstall lists of packages"
  printf '%s\n'   "Usage:"
  printf '\t%s\n' "${myname} debug | help | install [LIST] | reinstall [LIST]"
  printf '%s\n'   "[LIST]:"
  printf '\t%s\n' "the list of programs to install/reinstall, you can pass the list 'all'"
  printf '\t%s\n' "to install the programs from all the lists or a specific list"
  printf '\t%s\n' "the following lists are available:"
  printf '\t\t%-18s\t%-18s\n' "####   Var   ####" "####   Arg   ####"
  printf '\t\t%-18s\t%-18s\n' "\$packages" "packages"
  printf '\t\t%-18s\t%-18s\n' "\$zsh" "zsh"
  printf '\t\t%-18s\t%-18s\n' "\$console_prod" "console-prod"
  printf '\t\t%-18s\t%-18s\n' "\$compression" "compression"
  printf '\t\t%-18s\t%-18s\n' "\$min_setup" "min-setup"
  printf '\t\t%-18s\t%-18s\n' "\$downloading" "downloading"
  printf '\t\t%-18s\t%-18s\n' "\$vifm" "vifm"
  printf '\t\t%-18s\t%-18s\n' "\$printing" "printing"
  printf '\t\t%-18s\t%-18s\n' "\$other" "other"
  printf '\t\t%-18s\t%-18s\n' "\$flatpak" "flatpak"
  printf '\t\t%-18s\t%-18s\n' "\$graphics_drivers" "graphics-drivers"
  printf '\t\t%-18s\t%-18s\n' "\$devuan_base" "devuan-base"
  printf '\t%s\n' "to modify the lists write a file to \$XDG_CONFIG_HOME/install-list/proglist"
  printf '\t%s\n' "and inside write the modified program lists in one of the following formats:"
  printf '\t%s\n' "to append to the default lists:"
  printf '\t\t%s\n' "packages=\"\${packages} emacs ffmpeg\""
  printf '\t%s\n' "to overwrite the default lists:"
  printf '\t\t%s\n' "packages=\"emacs ffmpeg\""
  printf '\t%s\n' "besides the modifiable lists there exists some special lists that can be"
  printf '\t%s\n' "passed as arguments:"
  printf '\t\t%-18s\t%s\n' "all" "- all the lists"
  printf '\t\t%-18s\t%s\n' "devuan" "- all lists except printing and flatpak"
  printf '\t\t%-18s\t%s\n' "debian" "- all lists except printing, flatpak and devuan_base"
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

uselists="${configdir}/install-list/proglist"

if [ -f "$uselists" ]; then
  # yep, we do NOT check the contents just source them blindly
  # if the user wrote something bad it is his problem~~
  . "$uselists"
fi


case ${1} in
  debug)
    echo "the following packages are to be installed:"
    echo "general:"
    echo $packages
    echo "zsh:"
    echo $zsh
    echo "console productivity:"
    echo $console_prod
    echo "compression:"
    echo $compression
    echo "minimal setup:"
    echo $min_setup
    echo "downloading:"
    echo $downloading
    echo "vifm:"
    echo $vifm
    echo "devuan:"
    echo $devuan_base
    echo "printing and scanning support:"
    echo $printing
    echo "others:"
    echo $other
    echo "flatpak support:"
    echo $flatpak
    ;;
  install|reinstall)
    if [ -z "$2" ]; then
      echo "no packages selected!!!!"
      echo "select from the following list:"
      echo "    packages"
      echo "    zsh"
      echo "    console_prod"
      echo "    compression"
      echo "    min_setup"
      echo "    downloading"
      echo "    vifm"
      echo "    printing"
      echo "    other"
      echo "    flatpak"
      echo "    graphics_drivers"
      echo "    devuan_base"
      exit 1
    fi
    apt_act="$1"
    case $2 in
      all)
        tosintall="
        $packages
        $zsh
        $console_prod
        $compression
        $min_setup
        $downloading
        $vifm
        $printing
        $other
        $flatpak
        $graphics_drivers
        $devuan_base
        "
        apt $apt_act $tosintall
        ;;
      debian|ubuntu|nodevuan)
        tosintall="
        $packages
        $zsh
        $console_prod
        $compression
        $min_setup
        $downloading
        $vifm
        $other
        $graphics_drivers
        "
        apt $apt_act $tosintall
        ;;
      devuan-base|devuan_base)
        tosintall="
        $devuan_base
        "
        apt $apt_act $tosintall
        ;;
      nodebian|devuan)
        tosintall="
        $packages
        $zsh
        $console_prod
        $compression
        $min_setup
        $downloading
        $vifm
        $other
        $graphics_drivers
        $devuan_base
        "
        apt $apt_act $tosintall
        ;;
      general)
        apt $apt_act $packages
        ;;
      zsh)
        apt $apt_act $zsh
        ;;
      console|console-prod|console_prod)
        apt $apt_act $console_prod
        ;;
      compression|comp|zip|rar)
        apt $apt_act $compression
        ;;
      min-setup)
        apt $apt_act $min_setup
        ;;
      downloading|curl|megatools|download|dld)
        apt $apt_act $downloading
        ;;
      vifm)
        apt $apt_act $vifm
        ;;
      printing|scanning|printer|hplip)
        apt $apt_act $printing
        ;;
      other)
        apt $apt_act $other
        ;;
      flatpak)
        apt $apt_act $flatpak
        ;;
      drivers|graphics|graphics-drivers|graphics_drivers)
        apt $apt_act $graphics_drivers
        ;;
      *)
        echo "unknown package list $2"
        exit 1
        ;;
    esac
    ;;
  -h|--help|help)
    _help
    ;;
  *)
    echo "no option chosen, use debug, install or reinstall."
    exit 1
    ;;
esac

