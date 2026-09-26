# SUDO

Tweaks for sudo

## sudo_secure_path

A config file for the sudo secure path, the upstream sudo secure path does not include
`/usr/local/sbin` and `/usr/local/bin`, you can return the old default behaviour in debian and
devuan systems with this config file, if you so desire you can also alter the secure_path to add
other paths you want.

The script install.sh is included, it is a tiny scrip to install the config file with the correct
permissions required by sudo.
