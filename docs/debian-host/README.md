# Debian Host system

Steps:
1.  Enable Debian Host system with Intel Graphics SR-IOV
2.  Additional Settings to be done on host system to run Virtual Machine
3.  Installing Kubernetes, Kubevirt(customized to enable local display for Intel Graphics SR-IOV), Intel Device Plugin
4.  Creation of VM bootdisk image
5.  Deployment of VMs

## Enabling Debian Host system with Intel Graphics SR-IOV

Follow [ThunderSoft-SRIOV Guide](https://github.com/ThunderSoft-SRIOV/sriov) to enable Debian OS based Host system with Graphics SR-IOV Virtualization 
1.  Section [Prerequisites](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#prerequisites)
2.  Section [Preparation](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#preparation)
3.  Section [Host Setup](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#host-setup)
    1.  [Setup Host from PPA](https://github.com/ThunderSoft-SRIOV/sriov/blob/main/docs/setup_host_from_ppa.md) - Recommended
    2.  Or [Rebuild PPA package](https://github.com/ThunderSoft-SRIOV/sriov/blob/main/docs/build_package.md)

#### Ensure SR-IOV is enabled
```sh
sudo dmesg | grep -i i915
```
- Output:
    ```sh
    i915 0000:00:02.0: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version 13.00 stepping E0
    i915 0000:00:02.0: Running in SR-IOV PF mode
    i915 0000:00:02.0: [drm] VT-d active for gfx access
    i915 0000:00:02.0: vgaarb: deactivate vga console
    i915 0000:00:02.0: [drm] Using Transparent Hugepages
    i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=io+mem,decodes=io+mem:owns=io+mem
    i915 0000:00:02.0: [drm] Finished loading DMC firmware i915/adlp_dmc.bin (v2.20)
    i915 0000:00:02.0: [drm] GT0: GuC firmware i915/adlp_guc_70.bin version 70.36.0
    i915 0000:00:02.0: [drm] GT0: HuC firmware i915/tgl_huc.bin version 7.9.3
    i915 0000:00:02.0: [drm] GT0: HuC: authenticated for all workloads
    i915 0000:00:02.0: [drm] GT0: GUC: submission enabled
    i915 0000:00:02.0: [drm] GT0: GUC: SLPC enabled
    i915 0000:00:02.0: [drm] GT0: GUC: RC enabled
    [drm] Initialized i915 1.6.0 for 0000:00:02.0 on minor 0
    fbcon: i915drmfb (fb0) is primary device
    i915 0000:00:02.0: [drm] fb0: i915drmfb frame buffer device
    i915 0000:00:02.0: 7 VFs could be associated with this PF
    ```


## Additional Settings
These include creation of service to set Enabling Virtual Functions, Hugepage, USB permissions

1.  [Hugepage Service](../common/host-settings.md#setup-hugepages)
2.  [USB Permissions](../common/host-settings.md#set-permissions-to-usb-devices)
3.  [Enabling Virtual Functions and xhost](../common/host-settings.md#enable-gpu-virtual-functions)


## Installing Kubernetes, Kubevirt and Intel Device Plugin

1. [Install K3S](../common/kubevirt-offline-install.md#install-kubernetes)
2. [Install Kubevirt and Intel Device-Plugin](../common/kubevirt-offline-install.md#kubevirt-and-intel-device-plugin-installation-using-tar-files)

## Creation of Virtual Machine Bootdisk Image

1. [Windows Guest VM image creation](../../sample-application/create-bootdisk/README.md#windows-guest-vm-creation)
2. [Ubuntu Guest VM image creation](../../sample-application/create-bootdisk/README.md#ubuntu-guest-vm-creation)

## Deployment of Virtual Machines

1. [VM Deployment Guide](../../sample-application/discrete/README.md)