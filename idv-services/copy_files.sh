#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

if [ ! -d /usr/bin/idv ]; then
    echo "idv directory not found. Creating directory"
    sudo mkdir /usr/bin/idv
    sudo mkdir /usr/bin/idv/launcher
    sudo mkdir /usr/bin/idv/init
fi

# create/copy launcher files
sudo cp -r launcher /usr/bin/idv/

# create/copy init files
sudo cp -r init /usr/bin/idv/

# copy service files
sudo cp etc/systemd/user/idv-init.service /etc/systemd/user/idv-init.service
sudo cp etc/systemd/user/idv-launcher.service /etc/systemd/user/idv-launcher.service