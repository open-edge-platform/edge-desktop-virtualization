#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

if [ ! -d /usr/bin/idv ]; then
    echo "idv directory not found. Creating directory"
    sudo mkdir /usr/bin/idv
    sudo mkdir /usr/bin/idv/launcher
    sudo mkdir /usr/bin/idv/init
fi

username=$(getent passwd 1000 | cut -d: -f1)

# create/copy launcher files
sudo cp -r launcher /usr/bin/idv/

# create/copy init files
sudo cp -r init /usr/bin/idv/
sudo touch /usr/bin/idv/init/setup_sriov_vfs.log

# copy service files
sudo cp etc/systemd/user/idv-init.service /etc/systemd/user/idv-init.service
sudo cp etc/systemd/user/idv-launcher.service /etc/systemd/user/idv-launcher.service

# allow scripts to be run without password
echo "$username ALL=(ALL) NOPASSWD: /usr/bin/X,/usr/bin/idv/init/setup_sriov_vfs.sh,/usr/bin/idv/init/setup_display.sh,/usr/bin/idv/launcher/start_vm.sh,/usr/bin/idv/launcher/start_all_vms.sh,/usr/bin/idv/launcher/stop_vm.sh,/usr/bin/idv/launcher/stop_all_vms.sh" | sudo tee -a /etc/sudoers.d/guest > /dev/null
