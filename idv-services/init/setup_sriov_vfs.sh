#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.


# amount of spare GTT (Graphics Translation Table) memory to be allocated for the xe driver
GTT_SPARE_PF=$((500 * 1024 * 1024)) # MB
# number of spare contexts to be allocated for the xe driver
CONTEXT_SPARE_PF=9216
# number of spare doorbells to be allocated for the xe driver
DOORBELL_SPARE_PF=32
# set the default value for VF scheduling parameters
VFSCHED_EXECQ=25
VFSCHED_TIMEOUT=500000
NUMVFS=$(cat /sys/class/drm/card0/device/sriov_totalvfs)
VENDOR=$(cat /sys/bus/pci/devices/0000:00:02.0/vendor)
DEVICE=$(cat /sys/bus/pci/devices/0000:00:02.0/device)

function remove_sriov_vf() {
  echo -e "Remove provisioning dev-id: $DEVICE\n"
  echo '0' | tee -a /sys/class/drm/card0/device/sriov_numvfs
  echo $VENDOR $DEVICE | tee -a /sys/bus/pci/drivers/vfio-pci/remove_id
  rmmod vfio-pci
}

function validate_sriov_vf(){
  TotalVFs=`lspci | grep -i vga | cut -b 1-7 | cut -d "." -f2 | tail -n 1`
  if [[ $TotalVFs != $NUMVFS ]]; then
    echo -e "SRIOV enumeration failed."
    exit 1
    else
      echo -e "[$TotalVFs] VFs enumerated successfully."
  fi
}

function validate_vfio(){
  vfioDev=`ls /dev/vfio/`
  count=0

  for vfioDevNum in $vfioDev;
    do
      if [[ $vfioDevNum =~ ^[0-9]+$ ]]; then
        ((count++))
        echo "VFIO DeviceNum: $vfioDevNum"
      fi
    done

    if [[ $count !=  $NUMVFS ]]; then
      echo -e "VFIO Device Create Failed"
      remove_sriov_vf
      exit 1
    else
      echo -e "VFIO[$count] device created successfully."
    fi
}

function setup_sriov_vf() {
  # Setup iGPU SRIOV VF
  echo "Starting SR-IOV VF setup"
  local sriov_vfs
  # get the number of VFs
  sriov_vfs=$(cat /sys/class/drm/card0/device/sriov_numvfs)
  echo "Number of VFs: $sriov_vfs"
  if [[ "$sriov_vfs" -eq 0 ]]; then
      # VFs are not yet configured
      echo "VFs are not yet configured"
      # get the total number of VFs, vendor ID, device ID and DRM driver of the iGPU
      local drm_drv
      drm_drv=$(lspci -D -k -s 00:02.0 | grep "Kernel driver in use" | awk -F ':' '{print $2}' | xargs)
      echo "Total VFs: $NUMVFS, Vendor: $VENDOR, Device: $DEVICE, DRM Driver: $drm_drv"

      if [[ "$drm_drv" == "xe" ]]; then
          # DRM driver in use is “xe”, configure spare resources for “xe” driver
          echo "Configuring spare resources for xe driver"
          echo "$GTT_SPARE_PF" | sudo tee /sys/kernel/debug/dri/0/gt0/pf/ggtt_spare
          echo "$CONTEXT_SPARE_PF" | sudo tee /sys/kernel/debug/dri/0/gt0/pf/contexts_spare
          echo "$DOORBELL_SPARE_PF" | sudo tee /sys/kernel/debug/dri/0/gt0/pf/doorbells_spare
      fi

      # load the required kernel modules
      echo "Loading required kernel modules"
      sudo modprobe i2c-algo-bit || echo "Error: Failed to load i2c-algo-bit module"
      sudo modprobe video || echo "Error: Failed to load video module"

      # set the numvfs and bind the VFs to vfio_pci driver
      echo "Setting numvfs and binding VFs to vfio_pci driver"
      echo '0' | sudo tee /sys/bus/pci/devices/0000:00:02.0/sriov_drivers_autoprobe
      echo "$NUMVFS" | sudo tee /sys/class/drm/card0/device/sriov_numvfs
      echo '1' | sudo tee /sys/bus/pci/devices/0000:00:02.0/sriov_drivers_autoprobe

      sudo modprobe vfio-pci || echo "Error: Failed to load vfio-pci module"

      echo "$VENDOR $DEVICE" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id

      # configure for “i915” driver
      local iov_path
      if [[ "$drm_drv" == "i915" ]]; then
          iov_path="/sys/class/drm/card0/iov"
          [[ -d "/sys/class/drm/card0/prelim_iov" ]] && iov_path="/sys/class/drm/card0/prelim_iov"
      elif [[ "$drm_drv" == "xe" ]]; then
          iov_path="/sys/kernel/debug/dri/0000:00:02.0/gt0"
      fi
      echo "IOV Path: $iov_path"

      for (( i = 1; i <= totalvfs; i++ )); do
          for gt in gt gt0 gt1; do
              if [[ -d "${iov_path}/vf$i/$gt" ]]; then
                  echo "Configuring VF $i for $gt"
                  echo "$VFSCHED_EXECQ" | sudo tee "${iov_path}/vf$i/$gt/exec_quantum_ms"
                  echo "$VFSCHED_TIMEOUT" | sudo tee "${iov_path}/vf$i/$gt/preempt_timeout_us"
              fi
          done
      done

      # Check if all VFs are enumerated and vfios' are bound
      validate_sriov_vf
      validate_vfio

      echo "SR-IOV VF setup completed successfully"
  else
      echo "SR-IOV VFs are already enabled"
  fi
}

setup_sriov_vf
