#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# host-connect.sh - Script to launch xterm with access to host TTY
#
# This script allows connecting to the host system's TTY from within
# a Docker container running xterm

# Check if host TTY devices are accessible
if [ ! -d /dev/pts ] || [ ! -w /dev/pts ]; then
    echo "ERROR: Cannot access host TTY devices. Make sure /dev/pts is mounted."
    echo "Run the container with: -v /dev/pts:/dev/pts:rw"
    exit 1
fi

# Check for required privileges by attempting a simple namespace operation
if ! nsenter -t 1 -p true 2>/dev/null; then
    echo "ERROR: Cannot access host PID namespace. Missing required privileges."
    echo "Run the container with: --privileged --pid=host"
    exit 1
fi

# We need to access the host PID namespace to connect to the host TTY
if [ ! -e /proc/1/ns/pid ]; then
    echo "ERROR: Cannot access host PID namespace."
    echo "Make sure to run with: --pid=host"
    exit 1
fi

# Launch xterm with a command to connect to the host's login process
# Using all namespaces to ensure proper host access
# No fallback logic - if the connection fails, the container exits
exec xterm -T "Host TTY Connection" -e "nsenter -t 1 -m -u -i -n -p -- /bin/login"
