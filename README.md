# Edge Desktop Virtualization solution with Graphics SR-IOV

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/open-edge-platform/edge-desktop-virtualization/badge)](https://scorecard.dev/viewer/?uri=github.com/open-edge-platform/edge-desktop-virtualization)
[![CodeQL](https://github.com/open-edge-platform/edge-desktop-virtualization/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/open-edge-platform/edge-desktop-virtualization/actions/workflows/github-code-scanning/codeql)
[![Device Plugin: Coverity Scan](https://github.com/open-edge-platform/edge-desktop-virtualization/actions/workflows/device_plugin_coverity.yaml/badge.svg)](https://github.com/open-edge-platform/edge-desktop-virtualization/actions/workflows/device_plugin_coverity.yaml)

- [Edge Desktop Virtualization solution with Graphics SR-IOV](#edge-desktop-virtualization-solution-with-graphics-sr-iov)
  - [Overview](#overview)
    - [How it works](#how-it-works)
    - [Key Features](#key-features)
    - [Hardware requirements:](#hardware-requirements)
  - [Pre-requisites](#pre-requisites)
    - [System Requirements](#system-requirements)
      - [Recommended Hardware Configuration](#recommended-hardware-configuration)
    - [Build EMT](#build-emt)
      - [Pre-requisite](#pre-requisite)
      - [Image Build Steps](#image-build-steps)
    - [Install EMT](#install-emt)
    - [Generate Virtual Machine qcow2 with required drivers for SR-IOV](#generate-virtual-machine-qcow2-with-required-drivers-for-sr-iov)
    - [Further steps](#further-steps)
  - [IDV Services](#idv-services)
  - [Device Plugins for Kubernetes](#device-plugins-for-kubernetes)
  - [Kubevirt Patch](#kubevirt-patch)
  - [Sample Application : VM deployment Helm charts](#sample-application--vm-deployment-helm-charts)
    - [Discrete Helm charts](#discrete-helm-charts)
    - [Single Helm deployment](#single-helm-deployment)


## Overview

Intel's Single Root I/O Virtualization (SR-IOV) for graphics is a technology that allows a single physical Intel graphics processing unit (GPU) to be presented as multiple virtual devices to different virtual machines (VMs). This enables efficient GPU resource sharing and improves performance for graphics-intensive workloads within virtualized environments

### How it works

- A physical function (PF) manages the entire GPU on the host system.
- Virtual functions (VFs) are created from the PF and assigned to individual VMs.
- Each VF provides a dedicated and isolated path for data transfer to and from the VM, bypassing the host's hypervisor for improved performance.

### Key Features

- **Improved performance:** Direct access to the GPU hardware for each VM reduces overhead and latency, particularly for tasks like video transcoding and media processing.
- **Efficient resource utilization:** SR-IOV enables better sharing of GPU resources among multiple VMs, maximizing the utilization of a single physical GPU.
- **Support for cloud-native environments:** SR-IOV is crucial for enabling GPU acceleration in Kubernetes and other cloud platforms.

### Hardware requirements:
SR-IOV for Intel graphics typically requires hardware generation of Alder Lake (12th Gen Intel Core) or newer.
One can check if your Intel graphics controller supports SR-IOV by executing below command for the Single Root I/O Virtualization (SR-IOV) PCI capability
 ```sh
 sudo lspci -s 2.0 -v
 ```
![Graphics SR-IOV Support](docs/images/gfx-sriov-support.png "Graphics SR-IOV support")

## Pre-requisites

### System Requirements

Edge Microvisor Toolkit + Graphics SR-IOV is designed to support all Intel® Core platforms from 12th gen onwards.

This software is validated on below specifications:

|         Core™         |
| ----------------------|
| 12th Gen Intel® Core™ |
| 13th Gen Intel® Core™ |

#### Recommended Hardware Configuration

| Component    | Edge Microvisor Toolkit + graphics SR-IOV|
|--------------|-----------------------------------|
| CPU          | Intel® Core (12th gen and higher) |
| RAM          | 64GB recommended                  |
| Storage      | 500 GB SSD or NVMe minimum        |
| Networking   | 1GbE Ethernet                     |


### Build EMT

Reference to the build steps as mentioned here : [EMT Image build](https://github.com/smitesh-sutaria/edge-microvisor-toolkit/blob/3.0/docs/developer-guide/get-started/building-howto.md)

#### Pre-requisite
- Ubuntu 22.04
- Install the dependencies mentioned [here](https://github.com/open-edge-platform/edge-microvisor-toolkit/blob/3.0/toolkit/docs/building/prerequisites-ubuntu.md)

#### Image Build Steps

**Step 1: Clone EMT repo**
```bash
git clone https://github.com/open-edge-platform/edge-microvisor-toolkit.git
# checkout to the 3.0 tag
git checkout 3.0.20250411
```
**Step 2: Edit the Chroot env in the go code [toolkit/tools/internal/safechroot/safechroot.go](https://github.com/open-edge-platform/edge-microvisor-toolkit/blob/3.0.20250411/toolkit/tools/internal/safechroot/safechroot.go)**
```go
# add the following lines under "defaultChrootEnv" variable declaration, after the line 102
fmt.Sprintf("https_proxy=%s", os.Getenv("https_proxy")),
fmt.Sprintf("no_proxy=%s", os.Getenv("no_proxy")),
```
It should look something like this
![safechroot.go](docs/artifacts/proxy-go.png)

**Step 3: Build the toolkit**
```bash
cd edge-microvisor-toolkit/toolkit
sudo -E  make toolchain REBUILD_TOOLS=y
```
**Step 4: Build the image**
Build EMT image for graphics SR-IOV using the spec [edge-image-mf-dev.json](https://github.com/open-edge-platform/edge-microvisor-toolkit/blob/3.0-dev/toolkit/imageconfigs/edge-image-mf-dev.json)
```bash
sudo -E make image -j8 REBUILD_TOOLS=y REBUILD_PACKAGES=n CONFIG_FILE=imageconfigs/edge-image-mf-dev.json
# created image will be available under "edge-microvisor-toolkit/out/images/edge-image-mf-dev"
```
> ⚠️ **Note: Please remove "intel" related proxy from "no_proxy" system env variable before step 3**

### Install EMT

To Flash EMT DV image on a NUC follow [EMT image installation docs](https://github.com/intel-innersource/applications.virtualization.maverickflats-tiberos-itep/blob/vm_sidecar_dev_plugin/tiber/tiber_flash_partition.md)

To verify checkout [Other methods](https://github.com/smitesh-sutaria/edge-microvisor-toolkit/blob/3.0/docs/developer-guide/get-started/installation-howto.md)

### Generate Virtual Machine qcow2 with required drivers for SR-IOV

Follow the qcow2 creation for windows till post install launch from this readme.

https://github.com/ThunderSoft-SRIOV/sriov/blob/main/docs/deploy-windows-vm.md#microsoft-windows-11-vm

### Further steps

For further steps to launch VMs, refer the README [here](idv-services/README.md)

## [IDV Services](idv-services/README.md)
## [Device Plugins for Kubernetes](device-plugins-for-kubernetes/README.md)
## [Kubevirt Patch](kubevirt-patch/README.md)
## Sample Application : VM deployment Helm charts
   ### [Discrete Helm charts](sample-application/discrete/README.md)
   ### [Single Helm deployment](sample-application/single/README.md)