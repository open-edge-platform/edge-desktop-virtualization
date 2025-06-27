#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

source vm.conf

declare -A VM_LIST

if [[ -z "${guest}" ]]; then
  echo "Error: 'guest' variable is not set. Please define it in vm.conf."
  exit 1
fi

VM_LIST=()
for ((counter = 1; counter <= guest; counter++)); do
  vm="vm${counter}"
  VM_LIST[${#VM_LIST[@]}]=${vm}
done

trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM

for vm in "${VM_LIST[@]}"; do
    QEMU_OPTIONS=()
    name="${vm}_name"
    echo "Starting Guest ${!name} ..."
    QEMU_OPTIONS+=("-n" "${!name}")

    os="${vm}_os"
    QEMU_OPTIONS+=("-o" "${!os}")

    ram="${vm}_ram"
    QEMU_OPTIONS+=("-m" "${!ram}G")

    cpu="${vm}_cores"
    QEMU_OPTIONS+=("-c" "${!cpu}")

    firmware_file="${vm}_firmware_file"
    QEMU_OPTIONS+=("-f" "${!firmware_file}")

    qcow2_file="${vm}_qcow2_file"
    QEMU_OPTIONS+=("-d" "${!qcow2_file}")

    connector="${vm}_connector0"
    QEMU_OPTIONS+=("--display" "full-screen,connectors.0=${!connector}")

    ssh="${vm}_ssh"
    
    if [[ ${!os} == "windows" ]]; then
        winrdp="${vm}_winrdp"
        winrm="${vm}_winrm"
        QEMU_OPTIONS+=("-p" "ssh=${!ssh},winrdp=${!winrdp},winrm=${!winrm}")
    elif [[ ${!os} == "ubuntu" ]]; then
        QEMU_OPTIONS+=("-p" "ssh=${!ssh}")
    fi

    usb="${vm}_usb"
    if [ -n "${!usb}" ]; then
        QEMU_OPTIONS+=("-u" "${!usb}")
    fi

    sudo ./start_vm.sh "${QEMU_OPTIONS[@]}" &

    # Added sleep time of 3 seconds to make sure there is no issue related to swtpm socket
    sleep 3
done

wait
