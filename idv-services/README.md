# Desktop Virtualization solution with graphics SR-IOV

This file contains steps to launch virtual machines using a system service.

## Table of Contents
1. [Virtual machine configuration file](#virtual-machine-configuration-file)
2. [Modify VM configuration](#modify-vm-configuration)
3. [Run IDV services via an RPM package](#run-idv-services-via-an-rpm-package)
4. [Manual steps to run IDV service](#manual-steps-to-run-idv-service)
  - [Run script to copy necessary files to `/usr/bin` directory](#step-1-run-script-to-copy-necessary-files-to-usrbin-directory)
  - [Enable and start `idv-init` service](#step-2-enable-and-start-idv-init-service)
  - [Enable and start `idv-launcher` service](#step-3-enable-and-start-idv-launcher-service)
5. [Enable auto-login for the `guest` user](#enable-auto-login-for-the-guest-user)
6. [Post-Reboot Instructions](#post-reboot-instructions)
7. [Troubleshooting](#troubleshooting)

## Virtual machine configuration file 

- The `vm.conf` file in `launcher` directory consists of the following parameters. Each parameter defines a specific aspect of the virtual machine configuration: 

| Parameter           | Description                                      | Example Value                             |
|---------------------|--------------------------------------------------|-------------------------------------------|
| `vm1_ram`           | Memory allocated to the VM (in GB).              | `3`                                       |
| `vm1_os`            | Operating system of the VM.                      | `windows` or `ubuntu`                     |
| `vm1_name`          | Name of the VM.                                  | `vm1`                                     |
| `vm1_cores`         | Number of CPU cores allocated to the VM.         | `3`                                       |
| `vm1_firmware_file` | Path of firmware (.fd) file.                     | `/opt/qcow2/win1.fd`                      |
| `vm1_qcow2_file`    | Path of qcow2 file.                              | `/opt/qcow2/win1.qcow2`                   |
| `vm1_connector0`    | Display connector for the VM.                    | `HDMI-1`                                  |
| `vm1_usb`           | USB devices to attach (comma-separated)          | `3-1.1,3-1.2,3-1.3,3-1.4`                 |
| `vm1_ssh`           | SSH port for the VM.                             | `4444` (for windows), `2222` (for Ubuntu) |
| `vm1_winrdp`        | WinRDP port (Set this only for Windows VM)       | `3389`                                    |
| `vm1_winrm`         | WinRM port (Set this only for Windows VM)        | `5986`                                    |

- `vm1_usb` should be a comma separated list of USB devices to attach to the VM in the format: <hostbus>-<hostport>, where hostbus is the bus number and hostport is the end port to which the device is attached.

## Modify VM configuration

- Refer to the [Modify VM configuration file](modify-vm-config-file.md) for details on how to modify the VM configuration file.

## Run IDV services via an RPM package

- For detailed instructions on running IDV services using an RPM package, follow the instructions in [RPM Packaging Guide](rpm-packaging-guide.md).

## Manual steps to run IDV service

- If you prefer not to use the RPM package, follow these steps:

  ## Step 1: Run script to copy necessary files to `/usr/bin` directory

  - Run the `copy_files.sh` file with superuser privileges using the following command

    ```bash
    sudo chmod +x copy_files.sh
    sudo ./copy_files.sh
    ```
    This copies all the scripts and services to appropriate directories.

  ## Step 2: Enable and start `idv-init` service

    The `idv-init` service initializes the environment by enumerating SR-IOV virtual functions, starting the X server. This is a prerequisite for launching the virtual machines.

  - Run the following command to enable `idv-init` service
    
    ```bash
    systemctl --user enable idv-init.service
    ```

  - Run the following command to start `idv-init` service
    
    ```bash
    systemctl --user start idv-init.service
    ```

  - Verify that the service is running:

      ```bash
      systemctl --user status idv-init.service
      ```
    **Note**: After starting the idv-init service, the screen will go blank because X is running. Ensure you have SSH access to the machine for the next steps.

  ## Step 3: Enable and start `idv-launcher` service

    The `idv-launcher` service launches the configured virtual machines in their respective monitors.

  - Run the following command to enable `idv-launcher` service
    
    ```bash
    systemctl --user enable idv-launcher.service
    ```

  - Run the following command to start `idv-launcher` service
    
    ```bash
    systemctl --user start idv-launcher.service
    ```

  - Verify that the service is running:

    ```bash
    systemctl --user status idv-launcher.service
    ```
    **Note**: Once the idv-launcher service starts, all the VMs should be launched in respective monitors.

## Enable auto-login for the `guest` user

- To, enable auto-login for the `guest` user, place the [autologin.conf](autologin.conf) file in the `/etc/systemd/system/getty@tty1.service.d` directory. Run the following command from the `idv-services/` directory - 
  
  ```bash
  # Create `getty@tty1.service.d` if it doesn't exist
  sudo mkdir /etc/systemd/system/getty@tty1.service.d
  sudo cp autologin.conf /etc/systemd/system/getty@tty1.service.d/
  ```

  **Note**: When autologin is enabled for the `guest` user, they will be automatically logged in after each reboot.

## Post-Reboot Instructions

- If the machine is rebooted, navigate to the `idv-services/` directory and run the following command to reset permissions:

  ```bash
  sudo ./setup_permissions.sh
  ```
  - Once this script is executed, the IDV services (idv-int.service and idv-launcher.service) should start automatically. Verify their status using:
  
  ```bash
  systemctl --user status idv-int.service
  systemctl --user status idv-launcher.service
  ```

## Troubleshooting

- If the `idv-init` service fails to start, check the service logs using the following command:
  
  ```bash
  sudo journalctl -t idv-init-service
  ```
  Ensure that all required files are present in `/usr/bin/idv`.


- If the VMs do not launch after starting the `idv-launcher` service, check the service logs using the following command:

  ```bash
  sudo journalctl -t idv-launcher-service
  ```  
  Ensure that the `vm.conf` file is correctly configured and all required files (e.g., firmware and qcow2 files) are present and the file paths are valid.
