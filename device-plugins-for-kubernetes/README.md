# Device Plugins for Kubernetes to realize desktop virtualization

- [Device Plugins for Kubernetes to realize desktop virtualization](#device-plugins-for-kubernetes-to-realize-desktop-virtualization)
  - [Overview](#overview)
  - [Functionality](#functionality)
  - [Build](#build)
    - [Local Setup](#local-setup)
  - [Deploy](#deploy)
    - [Prerequisites](#prerequisites)
    - [Steps for Helm Chart installation](#steps-for-helm-chart-installation)
  - [Build and Deploy via designated registry](#build-and-deploy-via-designated-registry)
  - [Verify setup](#verify-setup)
  - [Usage](#usage)

This repository contains a device plugin for MaverikFlats that exposes five custom resources: `intel.com/x11`, `intel.com/udma`, `intel.com/vfio`, `intel.com/igpu` and `intel.com/usb`. This plugin allows you to request these resources in your pod specifications, enabling the mounting of necessary drivers/devices.

## Overview

Device plugins enable Kubernetes to manage specialized hardware resources, such as GPUs or high-performance network interfaces. This device plugin follows the Kubernetes device plugin API to advertise and manage the custom resources `intel.com/x11`, `intel.com/udma`, `intel.com/vfio`, `intel.com/igpu` and `intel.com/usb`.

## Functionality

The device plugin handles the following key functions[1]:

*   **Resource Advertisement:** The plugin advertises the availability of `intel.com/x11`, `intel.com/udma`, `intel.com/vfio`, `intel.com/igpu` and `intel.com/usb` resources to the kubelet.
*   **Allocation:** When a pod requests one or more of these resources, the kubelet calls the plugin's `Allocate` function.  The plugin then performs any device-specific setup and provides container runtime configurations to enable access to the requested resources. This may include:
    *   Mounting necessary device nodes
    *   Mounting necessary volumes

## Build
### Local Setup

To test it in local system, have a docker registry running in your system.
```shell
docker run -d -p 5000:5000 --name registry registry:2.7
```
This registry is accessible through port `5000`. To have the device-plugin up and running in your kubernetes system, you can run the `build.sh` file. This script will delete the existing device-plugin, if any, build, and optionally push to registry and create the deployment. You can adjust the resulting docker image tag & repository by changing the optional arguments `ver` (default "v1") and `repo` (default "127.0.0.1:5000"). Add `--push` to push to the repo after the image is successfully built.
```shell
./build.sh --ver v1 --repo "127.0.0.1:5000" --push
```

## Deploy

You can deploy the device plugin as a DaemonSet to ensure that it runs on every node in your cluster. You can deploy it as a helm package.

### Prerequisites

*   A working Kubernetes cluster with version above v1.26 that has device-plugin feature gate enabled
*   Appropriate privileges to deploy DaemonSets and create Kubernetes resources
* Helm installed in the system

### Steps for Helm Chart installation
1. Navigate to `deploy/helm/maverikflats-device-plugin` folder
2. Run `helm install device-plugin .`
```shell
➜ helm install device-plugin .
NAME: device-plugin
LAST DEPLOYED: Thu Mar 20 04:43:20 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

➜ kubectl get po -A
NAMESPACE     NAME                                                    READY   STATUS      RESTARTS   AGE
.
kube-system   device-plugin-maverikflats-device-plugin-zxkqm          1/1     Running     0          3s
.
```

## Build and Deploy via designated registry

1.  **Build the Device Plugin:** Build the device plugin binary using Go.
2.  **Push to registry:** Build and Push the image to your designated registry
3.  **Apply the DaemonSet:** Update `deploy/manifests/maverikflats-device-plugin.yaml` with the pushed image and deploy to your Kubernetes cluster using `kubectl apply -f deploy/manifests/maverikflats-device-plugin.yaml`.

## Verify setup

Upon having the device-plugin up and running, you should see the resources and resource count show up in your node(s).
```shell
➜  kubectl describe node
Name:               npgarch
Roles:              control-plane,etcd,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=rke2
.
.
.
Allocatable:
  cpu:                            128
  devices.kubevirt.io/kvm:        0
  devices.kubevirt.io/tun:        1k
  devices.kubevirt.io/vhost-net:  1k
  ephemeral-storage:              11219727512584
  intel.com/igpu:                 1k
  intel.com/udma:                 1k
  intel.com/x11:                  1k
  intel.com/usb:                  1k
  intel.com/vfio:                 1k
  memory:                         527946700Ki
  pods:                           110
System Info:
  Machine ID:                 7757898254f64f1f9b011129d1a2b021
.
.
.
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource                       Requests     Limits
  --------                       --------     ------
  cpu                            1730m (1%)   200m (0%)
  memory                         4917Mi (0%)  192Mi (0%)
  ephemeral-storage              0 (0%)       0 (0%)
  hugepages-1Gi                  0 (0%)       0 (0%)
  hugepages-2Mi                  0 (0%)       0 (0%)
  devices.kubevirt.io/kvm        0            0
  devices.kubevirt.io/tun        0            0
  devices.kubevirt.io/vhost-net  0            0
  intel.com/igpu                 0            0
  intel.com/udma                 0            0
  intel.com/x11                  0            0
  intel.com/x11                  0            0
  intel.com/x11                  0            0
Events:                          <none>
```

## Usage

To consume the custom resources, define them in your pod's resource requests.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mvf-test-pod
spec:
  containers:
    - name: test-container
      image: ubuntu
      command: ["sleep", "infinity"]
      resources:
        limits:
          intel.com/x11: 1
          intel.com/udma: 1
          intel.com/igpu: 1
          intel.com/vfio: 1
          intel.com/usb: 1
```
