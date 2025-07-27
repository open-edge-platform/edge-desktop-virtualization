<!-- Copyright (C) 2025 Intel Corporation -->
# Building EMT ISO with Desktop Virtualization (graphics SR-IOV)

- [Building EMT ISO with Desktop Virtualization (graphics SR-IOV)](#building-emt-iso-with-desktop-virtualization-graphics-sr-iov)
  - [Option-1 : Standalone (One-click) Build Script](#option-1--standalone-one-click-build-script)
    - [Run the script with default parameters](#run-the-script-with-default-parameters)
    - [Run the scripts with custom parameters](#run-the-scripts-with-custom-parameters)
    - [ISO file will be generated in the same path](#iso-file-will-be-generated-in-the-same-path)
    - [Demo : One-click EMT IDV ISO build script](#demo--one-click-emt-idv-iso-build-script)
  - [Option-2 : Manual Steps](#option-2--manual-steps)
    - [Pre-requisite](#pre-requisite)
    - [Step 1: clone the EMT repo](#step-1-clone-the-emt-repo)
    - [Step 2: Checkout the tag](#step-2-checkout-the-tag)
    - [Step 3: Copy the idv.json to edge-microvisor-toolkit/toolkit/imageconfigs/](#step-3-copy-the-idvjson-to-edge-microvisor-toolkittoolkitimageconfigs)
    - [Step 4: Build the tools](#step-4-build-the-tools)
    - [Step 5: Build the ISO for desktop virtualization (IDV)](#step-5-build-the-iso-for-desktop-virtualization-idv)
    - [Troubleshoot](#troubleshoot)
      - [Clean build](#clean-build)
      - [Working with Proxies](#working-with-proxies)
  - [Option-3 : Github Actions](#option-3--github-actions)
    - [Demo : EMT IDV ISO generation as part of github actions/workflow](#demo--emt-idv-iso-generation-as-part-of-github-actionsworkflow)

## Option-1 : Standalone (One-click) Build Script

> **Prerequisite** : Ubuntu 22.04 or Ubuntu 24.04

### Run the script with default parameters
```sh
sudo ./build_idv_iso.sh
```
Command line arguments are optional. Below default values will be used :
- Latest emt release tag : [3.0.20250718](https://github.com/open-edge-platform/edge-microvisor-toolkit/releases/tag/3.0.20250718)
- [idv.json](https://github.com/open-edge-platform/edge-desktop-virtualization/blob/main/emt-dv-iso/idv.json)

### Run the scripts with custom parameters

Build script supports 2 custom parameters (optional):
1. [-t *tag-name*] : This is the git release tag-name against which build should run.
2. [-f *image-config-json-file*] : This is the emt image config .json file. One can generate the custom images using this config file.

For ex:
```sh
sudo ./build_idv_iso.sh -t 3.0.20250718 -f ./idv.json
```

### ISO file will be generated in the same path

<p align="left">
<img align="center" width=50% height=50% src="docs/emt-idv-iso-out.png" >
</p>
<p align="center">
<em></em>
</p>

### Demo : One-click EMT IDV ISO build script

https://github.com/user-attachments/assets/8e3f609b-9632-4ea6-807d-1560856a20db

## Option-2 : Manual Steps

The image configuration is part of this repo [here](./idv.json)

### Pre-requisite

[Build Requirements](https://github.com/open-edge-platform/edge-microvisor-toolkit/blob/3.0/toolkit/docs/building/prerequisites-ubuntu.md#build-requirements-on-ubuntu)

> The steps and build requirements are common across ubuntu-24.04 and ubuntu-22.04
> It is recommended to built against a stable/release tag.


### Step 1: clone the EMT repo
```sh
git clone https://github.com/open-edge-platform/edge-microvisor-toolkit
```
### Step 2: Checkout the tag
```sh
cd edge-microvisor-toolkit
git checkout tags/<tag_name>
```
> The release tags can be found [here](https://github.com/open-edge-platform/edge-microvisor-toolkit/releases)

### Step 3: Copy the idv.json to edge-microvisor-toolkit/toolkit/imageconfigs/
```sh
wget https://github.com/open-edge-platform/edge-desktop-virtualization/blob/main/emt-dv-iso/idv.json
cp idv.json toolkit/imageconfigs/
```
> One can copy any custom idv.json file as per the requirement.

### Step 4: Build the tools
```sh
cd toolkit
sudo make toolchain REBUILD_TOOLS=y
```
### Step 5: Build the ISO for desktop virtualization (IDV) 
```sh
sudo make iso -j8 REBUILD_TOOLS=y REBUILD_PACKAGES=n CONFIG_FILE=./imageconfigs/idv.json
```
> ISO file will be generated @ 'edge-microvisor-toolkit/out/images'

### Troubleshoot

#### Clean build

For re-building with any other tags, its recommended to start clean and repeat above Steps 1 to 5.
 ```sh
cd edge-microvisor-toolkit
sudo make -C toolkit clean
```

#### Working with Proxies

If you are behind proxies and have them set, use -E option with all make commands
For ex :
```
sudo -E make toolchain REBUILD_TOOLS=y
sudo -E make iso -j8 REBUILD_TOOLS=y REBUILD_PACKAGES=n CONFIG_FILE=./imageconfigs/idv.json
```

## Option-3 : Github Actions

Generation of EMT IDV ISO can be part of github actions/workflow.

[Reference workflow file](https://raw.githubusercontent.com/open-edge-platform/edge-desktop-virtualization/refs/heads/main/.github/workflows/idv-iso-builder.yaml)

### Demo : EMT IDV ISO generation as part of github actions/workflow



