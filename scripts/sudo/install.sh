#!/bin/sh

sudo_secure_path_file=/etc/sudoers.d/sudo_secure_path

if [ -s "$sudo_secure_path_file" ]; then
    chmod 0775 "$sudo_secure_path_file"
fi

cp sudo_secure_path "$sudo_secure_path_file"

chmod 0440 "$sudo_secure_path_file"
