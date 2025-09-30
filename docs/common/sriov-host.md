# EMT Host system with Intel Graphics SR-IOV

Link to ISO creation - WIP

# Debian Host system with Intel Graphics SR-IOV

Follow [ThunderSoft-SRIOV Guide](https://github.com/ThunderSoft-SRIOV/sriov) to enable Debian OS based Host system with Graphics SR-IOV Virtualization 
1.  Section [Prerequisites](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#prerequisites)
2.  Section [Preparation](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#preparation)
3.  Section [Host Setup](https://github.com/ThunderSoft-SRIOV/sriov?tab=readme-ov-file#host-setup)
    1.  [Setup Host from PPA](https://github.com/ThunderSoft-SRIOV/sriov/blob/main/docs/setup_host_from_ppa.md) - Recommended
    2.  Or [Rebuild PPA package](https://github.com/ThunderSoft-SRIOV/sriov/blob/main/docs/build_package.md)

# Ubuntu Host system with Intel Graphics SR-IOV

## 12th Gen Intel® Core™ mobile processors (Code named Alder Lake-P) & 12th Gen Intel® Core™ desktop processors (Code named Alder Lake-S) Multi-OS with Graphics SRIOV Virtualization on Ubuntu

Follow [User Guide](https://www.intel.com/content/www/us/en/secure/content-details/680834/12th-gen-intel-core-mobile-processors-code-named-alder-lake-p-12th-gen-intel-core-desktop-processors-code-named-alder-lake-s-multi-os-with-graphics-sr-iov-virtualization-on-ubuntu-user-guide.html?wapkw=multi-os%20graphics%20SRIOV&DocID=680834)
1. Section `3.0 Host OS Kernel Build Steps`
2. Section `4.0 Host OS Platform System Requirements and Setup`
3. Till section `4.3 Set up the Host OS for SR-IOV`

## 13th Gen Intel® Core™ Mobile Processors for IoT Edge (Code named Raptor Lake - P) Multi-OS with Graphics SR-IOV Virtualization on Ubuntu

Follow [User Guide](https://www.intel.com/content/www/us/en/secure/content-details/762237/13th-gen-intel-core-mobile-processors-for-iot-edge-code-named-raptor-lake-p-multi-os-with-graphics-sr-iov-virtualization-on-ubuntu-user-guide.html?wapkw=multi-os%20graphics%20SRIOV&DocID=762237)
1.  Section `2.0 Host OS Platform System Requirements and Setup`
2.  Section `3.0 Ubuntu Kernel Setup`
3.  Section `4.0 Getting Started with Ubuntu* with Kernel Overlay`
4.  Section `5.0 Host OS and Guest OS Setup`
5.  Till section `5.1 Ubuntu Host Setup with SR-IOV`

## Reference Implementation of Intel® Core™ Ultra Processor/Intel® Core™ Ultra Processor (PS Series) (Formerly Known as Meteor Lake-U/H/PS) Multi-OS with Graphics SR-IOV Virtualization on Ubuntu

Follow [User Guide](https://www.intel.com/content/www/us/en/secure/content-details/780205/reference-implementation-of-intel-core-ultra-processor-intel-core-ultra-processor-ps-series-formerly-known-as-meteor-lake-u-h-ps-multi-os-with-graphics-sr-iov-virtualization-on-ubuntu-user-guide.html?wapkw=multi-os%20graphics%20SRIOV&DocID=780205)
1. Section `2.0 Host OS Platform System Requirements and Setup`
2. Section `3.0 Ubuntu* Kernel Setup`
3. Section `4.0 Host OS and Guest OS Setup`
4. Till section `4.1 Ubuntu* Host Setup with SR-IOV`

## Ensuring SR-IOV enablement
```sh
sudo dmesg | grep -i i915
```
- Output:
    ```sh
    [6.025993] i915 0000:00:02.0: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version 13.00 stepping E0
    [6.026008] i915 0000:00:02.0: Running in SR-IOV PF mode
    [6.026973] i915 0000:00:02.0: [drm] VT-d active for gfx access
    [6.027149] i915 0000:00:02.0: vgaarb: deactivate vga console
    [6.027220] i915 0000:00:02.0: [drm] Using Transparent Hugepages
    [6.027714] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=io+mem,decodes=io+mem:owns=io+mem
    [6.031499] i915 0000:00:02.0: [drm] Finished loading DMC firmware i915/adlp_dmc.bin (v2.20)
    [6.038683] i915 0000:00:02.0: [drm] GT0: GuC firmware i915/adlp_guc_70.bin version 70.44.1
    [6.038688] i915 0000:00:02.0: [drm] GT0: HuC firmware i915/tgl_huc.bin version 7.9.3
    [6.051800] i915 0000:00:02.0: [drm] GT0: HuC: authenticated for all workloads
    [6.052494] i915 0000:00:02.0: [drm] GT0: GUC: submission enabled
    [6.052497] i915 0000:00:02.0: [drm] GT0: GUC: SLPC enabled
    [6.053032] i915 0000:00:02.0: [drm] GT0: GUC: RC enabled
    [6.094472] [drm] Initialized i915 1.6.0 for 0000:00:02.0 on minor 0
    [6.284825] fbcon: i915drmfb (fb0) is primary device
    [6.709873] i915 0000:00:02.0: [drm] fb0: i915drmfb frame buffer device
    [6.736250] i915 0000:00:02.0: 7 VFs could be associated with this PF
    ```
