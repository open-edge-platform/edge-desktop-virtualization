#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

# Kill QEMU process
qemu_pid=$(pgrep -f "qemu.*$1")

if [ -n "$qemu_pid" ]; then
    echo "Stopping VM: $1"
    sudo kill -9 "$qemu_pid"
else
    echo "Could not find QEMU process for $1"
fi

# Kill swtpm process if it still exists
swtpm_pid=$(pgrep -f "swtpm.*$2")

if [ -n "$swtpm_pid" ]; then
    echo "Stopping swtpm process for $1"
    sudo kill -9 "$swtpm_pid"
fi

echo "*******************************************************"