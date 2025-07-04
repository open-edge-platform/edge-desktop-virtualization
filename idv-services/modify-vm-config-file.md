## Modify virtual machine configuration file

This document explains how to configure the `vm.conf` file, which is used to define the settings for virtual machines launched by the IDV solution. Proper configuration of this file is essential for ensuring the VMs are set up correctly with the desired resources and parameters.

- Modify the `launcher/vm.conf` to specify the number of VMs to launch and their respective settings. 

  - Set the `guest` variable to the number of VMs to launch.
  - Set the `OVMF_CODE_FILE` variable to the path of OVMF_CODE.fd file.
  - Fill in the required configuration parameters for each VM in the right order. If `guest` is set to `2`, modify/set the variables starting with `vm1_*` and `vm2_*`

  Example:

  ```ini
  # Number of VMs to launch
  guest=2
  
  # Path of OVMF_CODE.fd file
  OVMF_CODE_FILE=/opt/qcow2/OVMF_CODE.fd
  
  # Configuration for VM1
  vm1_ram=3
  vm1_os=windows
  vm1_name=windows_vm1
  vm1_cores=3
  vm1_firmware_file=/opt/qcow2/OVMF_VARS_windows1.fd
  vm1_qcow2_file=/opt/qcow2/win1.qcow2
  vm1_connector0=HDMI-1
  vm1_usb=3-1.1,3-1.2,3-1.3,3-1.4
  vm1_ssh=4444
  vm1_winrdp=3389
  vm1_winrm=5986

  # Configuration for VM2
  vm2_ram=3
  vm2_os=ubuntu
  vm2_name=ubuntu_vm1
  vm2_cores=3
  vm2_firmware_file=/opt/qcow2/ubuntu.fd
  vm2_qcow2_file=/opt/qcow2/ubuntu.qcow2
  vm2_connector0=HDMI-1
  vm2_usb=3-3.1,3-3.2,3-3.3,3-3.4
  vm2_ssh=2222
  ```

    **Note:** 
    - `vm1_usb`: Use the `<hostbus>-<hostport>` format to specify USB devices. For example, `3-1.1` refers to a device connected to bus 3, port 1.1.
    - `vm1_winrdp` and `vm1_winrm`: These parameters are only applicable for Windows VMs. Leave them unset for Ubuntu or other Linux-based VMs.
    - Set unique values for `ssh`, `winrdp` and `winrm` ports to avoid conflicts when launching multiple Windows VMs.
