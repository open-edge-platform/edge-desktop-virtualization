#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# This script sets NOPASSWD permissions to all users to execute certain scripts.

set -e

FILE="/etc/sudoers.d/idv_scripts"
ENTRY=$(cat <<EOF
ALL ALL=(ALL) NOPASSWD: /usr/bin/X, \
/usr/bin/idv/init/setup_sriov_vfs.sh, \
/usr/bin/idv/init/setup_display.sh, \
/usr/bin/idv/launcher/start_vm.sh, \
/usr/bin/idv/launcher/start_all_vms.sh, \
/usr/bin/idv/launcher/stop_vm.sh, \
/usr/bin/idv/launcher/stop_all_vms.sh
EOF
)

# If file does not exist, create one
if [ ! -f "$FILE" ]; then
    sudo touch "$FILE"
fi

# Check if the entry already exists, if not, add it
if ! sudo grep -Fxq "$ENTRY" "$FILE"; then
    echo "$ENTRY" | sudo tee -a "$FILE" > /dev/null
fi
