#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

# Kill QEMU process
grep_output=$(ps aux | grep qemu | grep -i $1)

if [ -n "$grep_output" ]; then
    pid=$(echo "$grep_output" | awk '{print $2}')
    echo "Stopping VM: $1"
    sudo kill -9 $pid
else
    echo "Could not find QEMU process for $1"
fi

# Kill swtpm process if it still exists
swtpm_grep_output=$(ps aux | grep swtpm | grep -i $2)

if [ -n "$swtpm_grep_output" ]; then
    pid=$(echo "$swtpm_grep_output" | awk '{print $2}')
    echo "Stopping swtpm process for $1"
    sudo kill -9 $pid
fi

echo "*******************************************************"
