# Ubuntu Host system

Steps:
1.  Enable Ubuntu Host system with Intel Grpahics SR-IOV
2.  Settings to be done on host system to enable running VMs
3.  Installing Kubernetes, Kubevirt(customized to enable local display for Intel Graphics SR-IOV), Intel Device Plugin
4.  Creation of VM bootdisk image
5.  Deployment of VMs

## Enabling Ubuntu Host system with Intel Grpahics SR-IOV

[Multi-OS with Graphics SR-IOV Virtualization on Ubuntu](https://www.intel.com/content/www/us/en/secure/content-details/762237/13th-gen-intel-core-mobile-processors-for-iot-edge-code-named-raptor-lake-p-multi-os-with-graphics-sr-iov-virtualization-on-ubuntu-user-guide.html?wapkw=multi-os%20graphics%20SRIOV&DocID=762237) [User Guide](https://cdrdv2.intel.com/v1/dl/getContent/762237?explicitVersion=true)

Follow Multi-OS with Graphics SR-IOV Virtualization on Ubuntu User Guide PDF 
1.  Section `2.0 Host OS Platform System Requirements and Setup`
2.  Section `3.0 Ubuntu Kernel Setup`
3.  Section `4.0 Getting Started with Ubuntu* with Kernel Overlay`
4.  Section `5.1 Ubuntu Host Setup with SR-IOV`

#### Ensure SR-IOV is enabled
```sh
sudo dmesg | grep -i i915
```
- Output:
    ```sh
    [6.246297] i915 0000:00:02.0: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version 13.00 stepping E0
    [6.246313] i915 0000:00:02.0: Running in SR-IOV PF mode
    [6.246876] i915 0000:00:02.0: [drm] VT-d active for gfx access
    [6.247005] i915 0000:00:02.0: vgaarb: deactivate vga console
    [6.247045] i915 0000:00:02.0: [drm] Using Transparent Hugepages
    [6.247542] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=io+mem,decodes=io+mem:owns=io+mem
    [6.251233] i915 0000:00:02.0: [drm] Finished loading DMC firmware i915/adlp_dmc.bin (v2.20)
    [6.257232] i915 0000:00:02.0: [drm] GT0: GuC firmware i915/adlp_guc_70.bin version 70.36.0
    [6.257236] i915 0000:00:02.0: [drm] GT0: HuC firmware i915/tgl_huc.bin version 7.9.3
    [6.270238] i915 0000:00:02.0: [drm] GT0: HuC: authenticated for all workloads
    [6.270998] i915 0000:00:02.0: [drm] GT0: GUC: submission enabled
    [6.270999] i915 0000:00:02.0: [drm] GT0: GUC: SLPC enabled
    [6.271507] i915 0000:00:02.0: [drm] GT0: GUC: RC enabled
    [6.326610] [drm] Initialized i915 1.6.0 for 0000:00:02.0 on minor 0
    [6.385387] fbcon: i915drmfb (fb0) is primary device
    [6.544458] i915 0000:00:02.0: [drm] fb0: i915drmfb frame buffer device
    [6.573481] i915 0000:00:02.0: 7 VFs could be associated with this PF
    ```

