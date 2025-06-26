#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

# shellcheck source=/dev/null
source vm.conf

declare -A VM_LIST

VM_LIST=()
for ((counter = 1; counter <= ${guest}; counter++)); do
  vm="vm${counter}"
  VM_LIST[${#VM_LIST[@]}]=${vm}
done

for vm in "${VM_LIST[@]}"; do
    name="${vm}_name"
    qcow2_file_path="${vm}_qcow2_file"
    sudo ./stop_vm.sh "${!name}" "${!qcow2_file_path}.d"
done

# wait until the start_vm script completes cleanup
sleep 2
