# Create Guest VM Disk Image
This step is to create VM Disk image using Kubevirt, this is a one time activity to create bootdisk, install required drivers and ensure SR-IOV is enabled on guest VM images. Once after disk image is created, image can be used for deployment of guest VMs

Manifest is provided in `sample-application/create-bootdisk/manifest/vm1.yaml`

## Windows Guest VM creation

**Pre-requisites:**
  - Windows 10/11 ISO
  - [Virtio ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso) for drivers
  - Latest [Intel GPU](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=861222) & [Zero Copy](https://www.intel.com/content/www/us/en/download/856334/display-virtualization-drivers-for-raptor-lake-ps.html?wapkw=sriov) drivers - Create ISO file with the drivers / Download directly on VM when Ethernet driver is installed and VM is able to connect to internet

1.  Convert the ISO files to RAW disk image
    ```sh
    qemu-img convert -f raw -O raw file.iso disk.img
    ```
2.  Place the RAW disk images derived from above ISO files in these locations
    | Image                           | PersistantVolume Name  | Path to store RAW disk Image                        |
    | :-----------------------------  | :--------------------: | :-------------------------------------------------  |
    | Windows ISO                     | cdisk-vm1-iso1-pv      | /opt/disk_imgs/iso/os-iso-disk/disk.img             |
    | Virtio ISO                      | cdisk-vm1-iso2-pv      | /opt/disk_imgs/iso/virtio-iso-disk/disk.img         |
    | Drivers ISO (If ISO is created) | cdisk-vm1-folder-pv    | /opt/disk_imgs/iso/drivers/disk.img                 |
    **Note: size of VM image is set to 60GB by default, edit `storage` parameter in `vm1.yaml` under `cdisk-vm1-bootdisk` to change it**
3.  Primary display considered in manifest is HDMI-1, hence deploy the Sidecar configmap of HDMI-1 and then apply manifest
    ```sh
    kubectl apply -f sample-application/discrete/sidecar/hdmi1.yaml
    kubectl apply -f sample-application/create-bootdisk/manifest/vm1.yaml
    ```
4.  Now you should see prompt to install OS on HDMI-1, now continue installation
5.  Refer [Multi-OS with Graphics SR-IOV Virtualization on Ubuntu User Guide PDF](https://www.intel.com/content/www/us/en/secure/content-details/762237/13th-gen-intel-core-mobile-processors-for-iot-edge-code-named-raptor-lake-p-multi-os-with-graphics-sr-iov-virtualization-on-ubuntu-user-guide.html?wapkw=multi-os%20graphics%20SRIOV&DocID=762237) Section `5.2.1 Windows* Guest VM Manual Setup`
    -  **Note: Use the latest Intel GPU and Zero drivers from link mentioned in Pre-requisites section**
    -  Continue from Section `5.2.1.2 Create Windows Guest VM Image from ISO` > `Step 2 Follow the Windows installation steps until you see the Windows Setup screen`.
    -  And complete installtion till `Section 5.2.1.12 Resume Windows Update`
6.  Once after OS installation is complete, shutdown the VM, remove the manifest
    ```sh
    kubectl delete -f sample-application/create-bootdisk/manifest/vm1.yaml
    kubectl delete -f sample-application/discrete/sidecar/hdmi1.yaml
    ```
7.  Copy the `disk.img` from `/opt/disk_imgs/create-vm-bootdisk` to desired location to deploy

## Ubuntu Guest VM creation

**Pre-requisites:**
  - Ubuntu 22.04/24.04 ISO

1.  Convert the Ubuntu ISO file to RAW disk image
    ```sh
    qemu-img convert -f raw -O raw file.iso disk.img
    ```
2.  Place the RAW disk images derived from above ISO files in these locations
    | Image                           | PersistantVolume Name  | Path to store RAW disk Image                        |
    | :-----------------------------  | :--------------------: | :-------------------------------------------------  |
    | Ubuntu ISO                      | cdisk-vm1-iso1-pv      | /opt/disk_imgs/iso/os-iso-disk/disk.img             |
3.  Primary display considered in manifest is HDMI-1, hence deploy the Sidecar configmap of HDMI-1 and then apply manifest
    ```sh
    kubectl apply -f sample-application/discrete/sidecar/hdmi1.yaml
    kubectl apply -f sample-application/create-bootdisk/manifest/vm1.yaml
    ```
4.  Now you should see prompt to install OS on HDMI-1, now continue installation
5.  Once after OS is installed, ensure internet is available and set the proxy if required. 
6.  Open a `Terminal` in the guest VM. Run the command shown below to upgrade Ubuntu software to the latest in the guest VM.
    ```sh
    # Upgrade Ubuntu software
    sudo apt -y update
    sudo apt -y upgrade
    sudo apt -y install openssh-server
    ```
7.  Copy [setup_bsp.sh](https://github.com/ThunderSoft-SRIOV/sriov/blob/main/scripts/setup_guest/ubuntu/setup_bsp.sh) to home directory of Ubuntu Guest
8.  Run `./setup_bsp.sh` in Ubuntu guest VM. Please be patient, it will take a few hours
    ```shell
    # in the guest
    cd ~
    sudo chmod +x setup_bsp.sh
    sudo ./setup_bsp.sh -kp 6.6-intel
    ```
9.  Do reboot, after rebooting, check if the kernel is the installed version.
    ```sh
    uname -r
    ```
    Output
    ```sh
    6.6-intel
    ```
10. Verify SR-IOV is enabled
    ```sh
    sudo dmesg | grep SR-IOV
    ```
    Output
    ```sh
    [6.026008] i915 0000:00:02.0: Running in SR-IOV VF mode
    ```
11.  Once after OS installation is complete, shutdown the VM, remove the manifest
    ```sh
    kubectl delete -f sample-application/create-bootdisk/manifest/vm1.yaml
    kubectl delete -f sample-application/discrete/sidecar/hdmi1.yaml
    ```
12.  Copy the `disk.img` from `/opt/disk_imgs/create-vm-bootdisk` to desired location to deploy