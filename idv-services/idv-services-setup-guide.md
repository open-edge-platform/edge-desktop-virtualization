# IDV Services Setup Guide for EMT Images

## Overview
- If you are using an EMT image with the prebuilt `intel-idv-services` package, you can follow this guide to start the IDV services.

## Table of Contents
  - [Steps to set up idv services on an immutable EMT image](#steps-to-set-up-idv-services-on-an-immutable-emt-image)
  - [Steps to set up idv services on a mutable EMT image](#steps-to-set-up-idv-services-on-a-mutable-emt-image)
  - [Modify VM configuration](#modify-vm-configuration)
  - [Reload system daemon](#reload-system-daemon)
  - [Setup Permissions for Running Scripts](#setup-permissions-for-running-scripts)
  - [Enable idv services](#enable-idv-services)
  - [Start `idv-init` service](#start-idv-init-service)
  - [Start `idv-launcher` service](#start-idv-launcher-service)
    - [Troubleshooting](#troubleshooting)

## Steps to set up idv services on an immutable EMT image

- To set up `idv-init` and `idv-launcher` services on an immutable image, the following has to be done via `cloud-init` - 
  1. Run the [setup_display](init/setup_display.sh) script to add xorg configuration files.
  2. Run the [setup permissions](setup_permissions.sh) script to set up permissions for running scripts.
  3. Enable auto-login for the user that is created. Refer to [Enable auto-login](README.md#enable-auto-login-for-the-guest-user)
  4. Enable `idv-init.service` and `idv-launcher.service`. Refer to the [Enable IDV Services](#enable-idv-services) section for the commands to be run to enable both the services. Set the value of `AUTOLOGIN_USER` in the `autologin.conf` to the user that is created.
  5. Start `idv-init.service` and `idv-launcher.service`. Refer to the [Start `idv-init.service`](#start-idv-init-service) and [Start `idv-launcher.service`](#start-idv-launcher-service) sections for the commands to be run to start each service.

## Steps to set up idv services on a mutable EMT image

- For a mutable EMT image, follow these steps to configure and start the IDV services:

### Modify VM configuration

- Modify the VM configuration file located at `/usr/bin/idv/launcher/vm.conf` to specify VM settings such as memory, CPU cores, and display connectors. For detailed instructions, refer to the [Modify VM configuration file](modify-vm-config-file.md) guide.

### Reload system daemon

- Run the following command to reload system daemon
    
  ```bash
  systemctl --user daemon-reload
  ```

### Setup Permissions for Running Scripts

- Run the following command to set up permissions for running scripts:

```bash
sudo chmod +x setup_permissions.sh
sudo ./setup_permissions.sh
```

### Enable idv services

- Run the following commands to enable `idv-init.service` and `idv-launcher.service`
  
  ```bash
  systemctl --user enable idv-init.service
  systemctl --user enable idv-launcher.service
  ```

### Start `idv-init` service

  The `idv-init` service initializes the environment by enumerating SR-IOV virtual functions, starting the X server. This is a prerequisite for launching the virtual machines.

- Run the following command to start `idv-init` service
    
    ```bash
    systemctl --user start idv-init.service
    ```

- Verify that the service is running:

  ```bash
  systemctl --user status idv-init.service
  ```
  **Note**: After starting the idv-init service, the screen will go blank because X is running. Ensure you have SSH access to the machine for the next steps.

### Start `idv-launcher` service

  The `idv-launcher` service launches the configured virtual machines in their respective monitors.

  - Run the following command to start `idv-launcher` service
    
    ```bash
    systemctl --user start idv-launcher.service
    ```

  - Verify that the service is running:

    ```bash
    systemctl --user status idv-launcher.service
    ```
    **Note**: Once the idv-launcher service starts, all the VMs should be launched in respective monitors.

**Note**: Autologin is enabled for the `guest` user. If the `idv-init` and `idv-launcher` services were enabled in the previous steps, they will automatically start upon autologin of the `guest` user.

## Troubleshooting

- If the `idv-init` service fails to start, check the service logs using the following command:
  
  ```bash
  journalctl --user -xeu idv-init.service
  ```

- If the VMs do not launch after starting the `idv-launcher` service, check the service logs using the following command:

  ```bash
  sudo journalctl -t idv-services
  ```  
  Ensure that the `vm.conf` file is correctly configured and all required files (e.g., firmware and qcow2 files) are present and the file paths are valid.
