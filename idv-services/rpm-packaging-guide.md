# Run IDV Services via RPM

This guide provides step-by-step instructions to package and run IDV services using RPM. It covers creating an RPM package, installing it, modifying configurations, and troubleshooting common issues.

## Table of Contents
1. [Modify VM configuration](#modify-vm-configuration)
2. [Install existing RPM package](#install-existing-rpm-package)
3. [Steps to Package and Install IDV Services](#steps-to-package-and-install-idv-services)
   - [Step 1: Create a Tar File](#step-1-create-a-tar-file)
   - [Step 2: Copy Files to RPM SOURCES](#step-2-copy-files-to-rpm-sources)
   - [Step 3: Setup Permissions for Running Scripts](#step-3-setup-permissions-for-running-scripts)
   - [Step 4: Setup RPM Environment](#step-4-setup-rpm-environment)
     - [Step 4.1: Install RPM](#step-41-install-rpm)
     - [Step 4.2: Install RPM-Build](#step-42-install-rpm-build)
     - [Step 4.3: Create the RPM Build Environment](#step-43-create-the-rpm-build-environment)
     - [Step 4.4: Configure the RPM Build Environment](#step-44-configure-the-rpm-build-environment)
   - [Step 5: Build the RPM Package](#step-5-build-the-rpm-package)
4. [Install RPM package](#install-rpm-package)
5. [Modify VM configuration post RPM installation](#modify-vm-configuration-post-rpm-installation)
6. [Uninstall RPM Package](#uninstall-rpm-package)
7. [Post-Reboot Instructions](#post-reboot-instructions)
8. [Troubleshooting](#troubleshooting)


## Modify VM configuration

- Refer to the [Modify VM configuration file](modify-vm-config-file.md) for details on how to modify the VM configuration file.

## Install existing RPM package

- If you have an existing RPM package, move to [Install RPM package](#install-rpm-package) section. 

## Steps to Package and Install IDV Services

### Step 1: Create a Tar File

- Run the following commands to create a tar file for the IDV solution:

```bash
sudo mkdir intel-idv-services-0.1
sudo cp -r autologin.conf etc/systemd/user/idv-init.service etc/systemd/user/idv-launcher.service init/ launcher/ intel-idv-services-0.1/
sudo tar -czf intel-idv-services-0.1.tar.gz intel-idv-services-0.1/
sudo chmod +x intel-idv-services-0.1.tar.gz
```

### Step 2: Copy Files to RPM SOURCES

```bash
sudo chmod +x setup_rpm_source.sh
./setup_rpm_source.sh
```
> **Note**: **Do not** run the above with sudo.

### Step 3: Setup Permissions for Running Scripts

- Run the following command to set up permissions for running scripts:

```bash
sudo chmod +x setup_permissions.sh
sudo ./setup_permissions.sh
```

### Step 4: Setup RPM Environment

  ### Step 4.1: Install RPM

    ```bash
    sudo -E dnf install rpm
    ```

  ### Step 4.2: Install RPM-Build

    ```bash
    sudo -E dnf install rpm-build
    ```

  ### Step 4.3: Create the RPM Build Environment

    ```bash
    mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    ```

  ### Step 4.4: Configure the RPM Build Environment

    ```bash
    echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
    ```

### Step 5: Build the RPM Package

  ```bash
  rpmbuild -ba ~/rpmbuild/SPECS/intel-idv-services.spec
  ```
  - If successful, the RPM package will be created in the `~/rpmbuild/RPMS/noarch/` directory. Make a note of the path of RPM package for further steps.
  > **Note**: If the build fails, check the .spec file for syntax errors or missing dependencies. 

## Install RPM package

  ```bash
  sudo rpm -ivh <path-to-rpm-package>
  ```
  
  **Note**: If the output of above command contains a message something similar to -

    ```ini
    Reload daemon failed: Transport endpoint is not connected
    Failed to start jobs: Transport endpoint is not connected
    ```
  
    Please verify the status of the service using the commands below. If the services have started, VMs will be launched in their respective monitors.

  - After installation, verify that the services are installed, enabled, and running:

    ```bash
    systemctl --user status idv-init.service
    systemctl --user status idv-launcher.service
    ```

## Modify VM configuration post RPM installation

- If you want to modify the VM configuration file after installing the RPM package:
  1. Stop and disable `idv-launcher.service`:

    ```bash
    systemctl --user stop idv-launcher.service
    systemctl --user disable idv-launcher.service
    ```
  
  2. Edit the `launcher/vm.conf` file:
    - Refer to the [Modify VM configuration file](modify-vm-config-file.md) for details on how to modify the VM configuration file.


  3. Re-enable and start `idv-launcher.service`:
    ```bash
    systemctl --user enable idv-launcher.service
    systemctl --user start idv-launcher.service
    ```

## Uninstall RPM Package

- To uninstall the RPM package, run:

  ```bash
  sudo rpm -e intel-idv-services
  ```

## Post-Reboot Instructions

- If the machine is rebooted, navigate to the `idv-services/` directory and run the following command to reset permissions:

  ```bash
  sudo ./setup_permissions.sh
  ```
  - Once this script is executed, the IDV services (idv-init.service and idv-launcher.service) should start automatically. Verify their status using:
  
  ```bash
  systemctl --user status idv-init.service
  systemctl --user status idv-launcher.service
  ```

## Troubleshooting

- If the `idv-init` service fails to start, check the journalctl logs using the following command:

  ```bash
  sudo journalctl -t idv-init-service
  ```
  Ensure that all required files are present in `/usr/bin/idv`.

- If the VMs do not launch after starting the `idv-launcher` service, check the journalctl logs using the following command:

  ```bash
  sudo journalctl -t idv-launcher-service
  ```  
  Ensure that the `vm.conf` file is correctly configured and all required files (e.g., firmware and qcow2 files) are present and the file paths are valid.
