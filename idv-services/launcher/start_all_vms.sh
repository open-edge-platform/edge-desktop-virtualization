#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

set -e

trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM

source vm.conf

if ! [[ "$guest" =~ ^[0-9]+$ ]] || (( guest < 1 || guest > 4 )); then
    echo "guest: Invalid value '$guest' (must be greater than 0 and less than or equal to 4)"
    exit 1
fi

if [[ -z "$OVMF_CODE_FILE" || ! -f "$OVMF_CODE_FILE" ]]; then
    echo "OMVF_CODE_FILE: '$OVMF_CODE_FILE' File does not exist"
    exit 1
fi

get_available_connectors() {
    local connectors=()

    # Check if xrandr is available
    if ! command -v xrandr >/dev/null 2>&1; then
        return 1
    fi

    # Fallback to regular xrandr if no monitors found
    if (( ${#connectors[@]} == 0 )); then
        while IFS= read -r line; do
            if [[ $line =~ ^([A-Z0-9-]+)[[:space:]]+connected ]]; then
                connectors+=("${BASH_REMATCH[1]}")
            fi
        done < <(xrandr 2>/dev/null)
    fi

    printf '%s\n' "${connectors[@]}"
}

# Helper function to check if connector is valid
is_valid_connector() {
    local connector="$1"
    local -a available_connectors=("${@:2}")

    local conn
    for conn in "${available_connectors[@]}"; do
        if [[ "$connector" == "$conn" ]]; then
            return 0
        fi
    done
    return 1
}

# Helper function to check total resource allocation
check_total_resources() {
    local total_ram=0
    local total_cores=0
    local available_ram available_cores
    
    # Get system resources
    available_ram=$(free -g | awk '/^Mem:/{print $2}')
    available_cores=$(nproc)
    
    # Calculate total allocation across all VMs
    for ((i = 1; i <= guest; i++)); do
        local ram_var="vm${i}_ram"
        local cores_var="vm${i}_cores"
        
        # Only add if variables exist and are valid
        if [[ -n "${!ram_var}" && "${!ram_var}" =~ ^[0-9]+$ ]]; then
            total_ram=$((total_ram + ${!ram_var}))
        fi
        if [[ -n "${!cores_var}" && "${!cores_var}" =~ ^[0-9]+$ ]]; then
            total_cores=$((total_cores + ${!cores_var}))
        fi
    done
    
    # Check if total allocation exceeds available resources
    local warnings=()
    if (( total_ram > available_ram )); then
        warnings+=("Total RAM allocation (${total_ram}GB) exceeds available RAM (${available_ram}GB)")
    fi
    if (( total_cores > available_cores )); then
        warnings+=("Total CPU cores allocation (${total_cores}) exceeds available cores (${available_cores})")
    fi
    
    # Print warnings if any
    if (( ${#warnings[@]} > 0 )); then
        echo "Resource allocation warnings:"
        for warning in "${warnings[@]}"; do
            echo "  Warning: $warning"
        done
        echo ""
    fi
}

validate_input_parameters() {
    local -a invalid_inputs=()
    declare -A connector0_seen ssh_seen usb_seen winrdp_seen winrm_seen

    local -a available_connectors

    mapfile -t available_connectors < <(get_available_connectors)
    if (( ${#available_connectors[@]} == 0 )); then
        echo "Warning: Could not detect available monitors. Please connect monitors to proceed further."
        exit 1
    else
        echo "Info: Detected connectors: ${available_connectors[*]}"
    fi

    for ((counter = 1; counter <= guest; counter++)); do
        vm="vm${counter}"
        os="${vm}_os"
        os_value="${!os}"

        # List of keys to check for each VM
        keys=(name connector0 os ram cores firmware_file qcow2_file usb ssh)
        [[ "$os_value" == "windows" ]] && keys+=(winrdp winrm)

        for key in "${keys[@]}"; do
            var="${vm}_$key"
            value="${!var}"

            case "$key" in
                name)
                    if [[ -z "$value" ]]; then
                        invalid_inputs+=("$var: Invalid value (empty)")
                    fi
                    ;;
                connector0)
                    if [[ -z "$value" ]]; then
                        invalid_inputs+=("$var: Invalid value (empty)")
                    elif [[ -n "${connector0_seen[$value]}" ]]; then
                        invalid_inputs+=("$var: Duplicate value '$value' (already used by ${connector0_seen[$value]})")
                    else
                        if ! is_valid_connector "$value" "${available_connectors[@]}"; then
                            invalid_inputs+=("$var: Invalid connector '$value' (available: ${available_connectors[*]})")
                        else
                            connector0_seen[$value]=$var
                        fi
                    fi
                    ;;
                os)
                    if [[ "$value" != "windows" && "$value" != "ubuntu" ]]; then
                        invalid_inputs+=("$var: Invalid value '$value' (must be 'windows' or 'ubuntu')")
                    fi
                    ;;
                ram)
                    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value <= 0 )); then
                        invalid_inputs+=("$var: Invalid value '$value' (must be integer > 0)")
                    else
                      local min_ram=2
                      if (( value < min_ram )); then
                        invalid_inputs+=("$var: RAM ${value}GB is below minimum requirement of ${min_ram}GB")
                      elif (( value > 64 )); then
                        invalid_inputs+=("$var: RAM ${value}GB is too high (maximum 64GB supported)")
                      fi
                    fi
                    ;;
                cores)
                  if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value <= 0 )); then
                        invalid_inputs+=("$var: Invalid value '$value' (must be integer > 0)")
                  else
                    local available_cores
                    available_cores=$(nproc)
                    if (( value > available_cores )); then
                      invalid_inputs+=("$var: CPU cores '$value' exceeds available cores '$available_cores'")
                    elif (( value > 16 )); then
                      invalid_inputs+=("$var: CPU cores too high '$value' (maximum 16 cores supported)")
                    fi
                  fi
                  ;;
                firmware_file|qcow2_file)
                    if [[ -z "$value" || ! -f "$value" ]]; then
                        invalid_inputs+=("$var: File does not exist: '$value'")
                    fi
                    ;;
                usb)
                    if [[ -n "$value" ]]; then
                        IFS=',' read -ra usb_arr <<< "$value"
                        for pair in "${usb_arr[@]}"; do
                            if ! [[ "$pair" =~ ^[0-9]+-[0-9]+\.[0-9]+$ ]]; then
                                invalid_inputs+=("$var: Invalid USB device format: '$pair' (expected <bus>-<port>)")
                            elif [[ -n "${usb_seen[$pair]}" ]]; then
                                invalid_inputs+=("$var: Duplicate USB device '$pair' (already used by ${usb_seen[$pair]})")
                            else
                                usb_seen[$pair]=$var
                            fi
                        done
                    fi
                    ;;
                ssh|winrdp|winrm)
                    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < 1 || value > 65535 )); then
                        invalid_inputs+=("$var: Invalid port number: '$value' (must be 1-65535)")
                    else
                        # Uniqueness check
                        case "$key" in
                            ssh)
                                if [[ -n "${ssh_seen[$value]}" ]]; then
                                    invalid_inputs+=("$var: Duplicate value '$value' (already used by ${ssh_seen[$value]})")
                                else
                                    ssh_seen[$value]=$var
                                fi
                                ;;
                            winrdp)
                                if [[ -n "${winrdp_seen[$value]}" ]]; then
                                    invalid_inputs+=("$var: Duplicate value '$value' (already used by ${winrdp_seen[$value]})")
                                else
                                    winrdp_seen[$value]=$var
                                fi
                                ;;
                            winrm)
                                if [[ -n "${winrm_seen[$value]}" ]]; then
                                    invalid_inputs+=("$var: Duplicate value '$value' (already used by ${winrm_seen[$value]})")
                                else
                                    winrm_seen[$value]=$var
                                fi
                                ;;
                        esac
                    fi
                    ;;
            esac
        done
    done

    check_total_resources

    if (( ${#invalid_inputs[@]} > 0 )); then
        echo "Invalid VM configuration detected:"
        for msg in "${invalid_inputs[@]}"; do
            echo "  $msg"
        done
        exit 1
    fi
}

validate_input_parameters

declare -A VM_LIST

VM_LIST=()
for ((counter = 1; counter <= guest; counter++)); do
  vm="vm${counter}"
  VM_LIST[${#VM_LIST[@]}]=${vm}
done

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