# Building Kubevirt and patching QEMU

This document provides steps, related to
- Patching QEMU with Intel GPU SR-IOV patches and replacing the version of QEMU in Kubevirt
- Enabling Kubevirt to support local display by enabling GTK library support

## Overview

The following will be captured in this document:

- Patch Qemu with Intel Graphics SR-IOV patches
  - Patch QEMU source code on Ubuntu host using the SR-IOV patches
  - Build QEMU within a Centos 9 image container
- Enable Kubevirt with libraries to support GTK local display
  - Copy the patched QEMU to GTK enabled Kubevirt
  - Patch Kubevirt files to include QEMU
  - Build and Deploy Kubevirt

> [!Note]
> This has been verified on `Kubevirt Version v1.5.0`
> OS and QEMU version provided in default Kubevirt virt-launcher image is

```shell
cat /etc/os-release
NAME="CentOS Stream" VERSION="9"

/usr/libexec/qemu-kvm --version
QEMU emulator version 9.0.0 (qemu-kvm-9.0.0-10.el9)
```

## 1. Build System Setup

> [!Note]
> Build system where the Kubevirt and QEMU build performed is Ubuntu 22.04 LTS

1. Install a container frontend and setup the registry.
    Both `podman` and `docker` will work. `podman` is recommended and used in this guide.
    ```sh
    sudo apt -y install podman

    podman run -d -p 5000:5000 --name local-registry registry:2
    ```

## 2. Building and patching QEMU

The SRIOV patches to QEMU are based on QEMU 8.2.1

1. Download the SR-IOV patches for QEMU

    ```sh
    cd ~/workspace

    wget -N --no-check-certificate https://download.01.org/intel-linux-overlay/ubuntu/pool/main/q/qemu/qemu_8.2.1+ppa1-noble9.debian.tar.xz

    mkdir qemu_8.2.1+ppa1-noble9.debian
    tar -xf 'qemu_8.2.1+ppa1-noble9.debian.tar.xz' -C 'qemu_8.2.1+ppa1-noble9.debian'
    ```

1. Download the same version of QEMU that matches the downloaded patches:

    ```sh
    wget -N --no-check-certificate https://download.qemu.org/qemu-8.2.1.tar.xz

    tar -xf qemu-8.2.1.tar.xz

    cd qemu-8.2.1
    ```

1. Copy the patches from `qemu_8.2.1+ppa1-noble9.debian` to qemu-8.2.1 directory:

    ```sh
    cp  -r ../qemu_8.2.1+ppa1-noble9.debian/debian/patches/sriov/ .
    ```

1. Apply patches:

    ```sh
    git apply ./sriov/*.patch
    ```

### 2.1 Creating CentOS 9 containerized environment

QEMU is built in Centos 9 container environment to ensure compatible with the Centos 9 based container image for virt-launcher.

The original idea to build within the Centos container comes from this [link](https://github.com/alicefr/kubevirt-debug/tree/main/build-with-custom-files#build-kubevirt-with-qemu-from-source-code)

1. Generate the Centos 9 image to be used for QEMU build environment

    ```sh
    ./tests/lcitool/libvirt-ci/bin/lcitool --data-dir ./tests/lcitool dockerfile centos-stream-9 qemu > Dockerfile.centos-stream9
    ```

1. Patch `Dockerfile.centos-stream9` to include missing dependencies

    ```sh
    perl -p -i -e 's|zstd &&|zstd libslirp-devel liburing-devel libbpf-devel libblkio-devel &&|g' Dockerfile.centos-stream9
    ```

    This makes the following changes to `Dockerfile.centos-stream9`

    ```diff
            zlib-devel \
            zlib-static \
    -        zstd && \
    +        zstd libslirp-devel liburing-devel libbpf-devel libblkio-devel && \
        dnf autoremove -y && \
        dnf clean all -y && \
        rpm -qa | sort > /packages.txt && \
    ```
    > [!Note]
    > All expected dependencies for QEMU build in this example are there after the patch - if QEMU will be built with other flags it is possible that some dependencies may be missing and will need to be added to this Dockerfile.

    If needed, add proxy environment variables to the top of this Dockerfile.centos-stream9 (use an appropriate proxy, such as proxy-dmz or proxy-iind).
    ```
    ENV HTTPS_PROXY "http://proxy-dmz.intel.com:912"
    ENV HTTP_PROXY "http://proxy-dmz.intel.com:912"
    ```

1. Build the Centos 9 image

    ```sh
    podman build -t qemu_build:centos-stream9 -f Dockerfile.centos-stream9 .
    ```

1. Starting Centos 9 build environment

    Start the Centos 9 environment container from `qemu-8.2.1` directory. This allows the whole content of the QEMU source to be inside the environment.

    ```sh
    cd qemu-8.2.1

    podman run -ti \
        -v $(pwd):/src:Z \
        -w /src  \
        --security-opt label=disable \
        qemu_build:centos-stream9
    ```

### 2.2 Building QEMU inside the Centos 9 container

1. Configure QEMU build

    ```sh
    [root@<container> src]# ./configure --prefix=/usr --enable-kvm --disable-xen --enable-libusb --enable-debug-info --enable-debug  --enable-sdl --enable-vhost-net --enable-spice --disable-debug-tcg  --enable-opengl  --enable-gtk  --enable-virtfs --target-list=x86_64-softmmu --audio-drv-list=pa --firmwarepath=/usr/share/qemu-firmware:/usr/share/ipxe/qemu:/usr/share/seavgabios:/usr/share/seabios:/usr/share/qemu-kvm/ --disable-spice
    ```

    > [!Note]
    > Certain flags were added to the default configure command to enable **GTK on local display**:
    > * spice is disabled with --disable-spice (spice is not natively supported in RHEL9 image)
    > * Firmware paths necessary for the operation of VM within the virt-launcher pods are added `--firmwarepath=/usr/share/qemu-firmware:/usr/share/ipxe/qemu:/usr/share/seavgabios:/usr/share/seabios:/usr/share/qemu-kvm/`


1. Build QEMU

    ```sh
    [root@<container> src]# cd build
    [root@<container> src]# ninja
    [root@<container> src]# ninja install
    ```

1. Exit the CentOS build container environment - the built artifacts will be present in the `qemu-8.2.1` directory on host.

    ```sh
    [root@<container> src]# exit
    ```
    On build system:
    ```sh
    ls -la build/qemu-system-x86_64
    -rwxr-xr-x 1 user user 47M Feb 13 14:27 build/qemu-system-x86_64

    sha256sum build/qemu-system-x86_64
    13c2760bf012a8011ddbe0c595ec3dca24249debe32bc4d1e338ec8538ad7453 build/qemu-system-x86_64
    ```

## 3. Enabling Kubevirt with GTK display support libraries

1. Clone the kubevirt repo:

    ```sh
    mkdir -p ~/workspace
    cd ~/workspace
    git clone https://github.com/kubevirt/kubevirt.git
    cd kubevirt
    ```

1. Check out the specific kubevirt version you want to build with.
    ```
    git checkout v1.5.0
    ```

1. Apply a patch to kubevirt to update dependencies which resolve potential security issues since the original v1.5.0 kubevirt was released. $EDV_HOME should be set to the path to the top level of this repository (e.g. edge-desktop-virtualization).
    ```sh
    git apply $EDV_HOME/kubevirt-patch/0001-Bump-dependency-versions-for-kubevirt-v1.5.0.patch
    ```

1. [OPTIONAL] Update kubevirt dependency images using the `make bump-images` command. Note that you may also have to update `go_version` in `WORKSPACE` if applicable.

1. Apply the kubevirt patch from this repo to expand kubevirt virt-launcher image with additional dependencies to support GTK
    ```sh
    git apply $EDV_HOME/kubevirt-patch/0001-Patching-Kubevirt-with-GTK-libraries_v1.patch
    ```

1. Create a directory to place the custom QEMU binary and copy it from the QEMU build

    ```sh
    mkdir build
    cp ../qemu-8.2.1/build/qemu-system-x86_64 build/qemu-system-x86_64
    ```

1. Obtain the `SHA` hash number of the QEMU binary

    ```sh
    QEMU_SHA256="$(sha256sum ./build/qemu-system-x86_64 | cut -d ' ' -f 1)"
    echo "QEMU_SHA256=$QEMU_SHA256"
    ```

1. Patch the top level `WORKSPACE` file in top level `kubevirt` directory. Replace `<SHA256SUM_OF_PATCHED_QEMU>` with your sha256sum from the previous step
    ```sh
    perl -p -i -e "s|<SHA256SUM_OF_PATCHED_QEMU>|$QEMU_SHA256|g" WORKSPACE
    ```

1. Export the location of the docker registry and build tag (local docker registry in this case)

    ```sh
    export DOCKER_PREFIX=localhost:5000
    export DOCKER_TAG=mybuild
    ```

    If you are building on a corporate network, ensure HTTP_PROXY and HTTPS_PROXY are set correctly. They must be the uppercase variants, the lowercase versions are not used by the kubevirt build scripts.
    ```sh
    export HTTPS_PROXY="http://proxy-dmz.intel.com:912"
    export HTTP_PROXY="http://proxy-dmz.intel.com:912"
    ```

1. Build Kubevirt & dependencies.
    ```sh
    make rpm-deps
    make all
    make bazel-build-images
    ```

1. Push the images to the local Docker registry

    ```sh
    make push
    ***
    2025/02/13 15:43:38 Successfully pushed Docker image to localhost:5000/network-passt-binding:mybuild
    BUILD_ARCH= DOCKER_PREFIX=localhost:5000 DOCKER_TAG=mybuild hack/push-container-manifest.sh
    ```

1. Build manifests referencing the image locations

    ```sh
    make manifests
    ```

1. To install Kubevirt
    ```sh
    kubectl apply -f _out/manifests/release/kubevirt-operator.yaml
    kubectl apply -f _out/manifests/release/kubevirt-cr.yaml
    ```

1.  Verify Deployment
    ```sh
    kubectl get all -n kubevirt

    NAME                                   READY   STATUS    RESTARTS      AGE
    pod/virt-api-999875d56-4dvsc           1/1     Running   6 (18d ago)   19d
    pod/virt-controller-546cb985cd-f4zns   1/1     Running   5 (18d ago)   19d
    pod/virt-controller-546cb985cd-kxmsr   1/1     Running   5 (18d ago)   19d
    pod/virt-handler-s4m9j                 1/1     Running   7 (15d ago)   19d
    pod/virt-operator-6459bcf8c6-vxbqx     1/1     Running   6 (18d ago)   19d
    pod/virt-operator-6459bcf8c6-xhktx     1/1     Running   6 (18d ago)   19d

    NAME                                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    service/kubevirt-operator-webhook     ClusterIP   10.43.86.170   <none>        443/TCP   19d
    service/kubevirt-prometheus-metrics   ClusterIP   None           <none>        443/TCP   19d
    service/virt-api                      ClusterIP   10.43.68.37    <none>        443/TCP   19d
    service/virt-exportproxy              ClusterIP   10.43.189.94   <none>        443/TCP   19d

    NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    daemonset.apps/virt-handler   1         1         1       1            1           kubernetes.io/os=linux   19d

    NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/virt-api          1/1     1            1           19d
    deployment.apps/virt-controller   2/2     2            2           19d
    deployment.apps/virt-operator     2/2     2            2           19d

    NAME                                         DESIRED   CURRENT   READY   AGE
    replicaset.apps/virt-api-6676df49cc          0         0         0       19d
    replicaset.apps/virt-api-999875d56           1         1         1       19d
    replicaset.apps/virt-controller-546cb985cd   2         2         2       19d
    replicaset.apps/virt-controller-54c7869f6c   0         0         0       19d
    replicaset.apps/virt-operator-6459bcf8c6     2         2         2       19d

    NAME                            AGE   PHASE
    kubevirt.kubevirt.io/kubevirt   19d   Deployed
    ```

## 4. Kubevirt installation using local tar files (ideal for deployment on Host system not connected to network)

**On Development System**

1.  Pull Docker Images from registry
    ```sh
    docker pull localhost:5000/sidecar-shim:mybuild
    docker pull localhost:5000/virt-handler:mybuild
    docker pull localhost:5000/virt-controller:mybuild
    docker pull localhost:5000/virt-launcher:mybuild
    docker pull localhost:5000/virt-api:mybuild
    docker pull localhost:5000/virt-operator:mybuild
    ```
    Optional to tag the images
    ```sh
    docker tag localhost:5000/sidecar-shim:mybuild myregistry:5000/sidecar-shim:v1
    ```

2.  Save the images to tar files for transfer
    ```sh
    docker save -o sidecar-shim.tar localhost:5000/sidecar-shim:mybuild
    docker save -o virt-api.tar localhost:5000/virt-api:mybuild
    docker save -o virt-controller.tar localhost:5000/virt-controller:mybuild
    docker save -o virt-handler.tar localhost:5000/virt-handler:mybuild
    docker save -o virt-launcher.tar localhost:5000/virt-launcher:mybuild
    docker save -o virt-operator.tar localhost:5000/virt-operator:mybuild
    ```
3.  Modify the `kubevirt-operator.yaml` file with the following changes
    ```yaml
    env:
    - name: VIRT_OPERATOR_IMAGE
      value: localhost:5000/virt-operator:mybuild
    - name: WATCH_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.annotations['olm.targetNamespaces']
    - name: KUBEVIRT_VERSION
      value: mybuild
    image: localhost:5000/virt-operator:mybuild
    imagePullPolicy: IfNotPresent
    ```
4.  Copy the above `.tar` files, `kubevirt-operator.yaml` and `kubevirt-cr.yaml` to deployment system.

**On Deployment system**

5.  Ensure Kubernetes is installed and local cluster is running.
6.  Import the images into the container runtime
    ```sh
    sudo ctr -n k8s.io images import sidecar-shim.tar
    sudo ctr -n k8s.io images import virt-api.tar
    sudo ctr -n k8s.io images import virt-controller.tar
    sudo ctr -n k8s.io images import virt-handler.tar
    sudo ctr -n k8s.io images import virt-launcher.tar
    sudo ctr -n k8s.io images import virt-operator.tar
    ```
    Alternatively 
    ```sh
    sudo k3s ctr i import virt-operator.tar
    sudo k3s ctr i import virt-api.tar
    sudo k3s ctr i import virt-controller.tar
    sudo k3s ctr i import virt-handler.tar
    sudo k3s ctr i import virt-launcher.tar
    sudo k3s ctr i import sidecar-shim.tar

    sudo k3s ctr i import device-plugin.tar
    sudo k3s ctr i import busybox.tar
    ```
7.  Verify the images are imported correctly
    ```sh
    sudo crictl images | grep localhost

    localhost:5000/sidecar-shim                             mybuild           c48d79a700926       51.5MB
    localhost:5000/virt-api                                 mybuild           025a39d7f7504       28.6MB
    localhost:5000/virt-controller                          mybuild           d1cb23d032aa0       27.9MB
    localhost:5000/virt-handler                             mybuild           a9bd1a37e2e0c       90.7MB
    localhost:5000/virt-launcher                            mybuild           c69ddc6b90387       403MB
    localhost:5000/virt-operator                            mybuild           99462ddb3a866       39.8MB
    ```
8.  Deploy Kubevirt by applying Kubevirt operator and custom resource YAML
    ```sh
    kubectl apply -f kubevirt-operator.yaml
    kubectl apply -f kubevirt-cr.yaml
    ```
9.  Verify Deployment
    ```sh
    kubectl get all -n kubevirt

    NAME                                   READY   STATUS    RESTARTS      AGE
    pod/virt-api-999875d56-4dvsc           1/1     Running   6 (18d ago)   19d
    pod/virt-controller-546cb985cd-f4zns   1/1     Running   5 (18d ago)   19d
    pod/virt-controller-546cb985cd-kxmsr   1/1     Running   5 (18d ago)   19d
    pod/virt-handler-s4m9j                 1/1     Running   7 (15d ago)   19d
    pod/virt-operator-6459bcf8c6-vxbqx     1/1     Running   6 (18d ago)   19d
    pod/virt-operator-6459bcf8c6-xhktx     1/1     Running   6 (18d ago)   19d

    NAME                                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    service/kubevirt-operator-webhook     ClusterIP   10.43.86.170   <none>        443/TCP   19d
    service/kubevirt-prometheus-metrics   ClusterIP   None           <none>        443/TCP   19d
    service/virt-api                      ClusterIP   10.43.68.37    <none>        443/TCP   19d
    service/virt-exportproxy              ClusterIP   10.43.189.94   <none>        443/TCP   19d

    NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    daemonset.apps/virt-handler   1         1         1       1            1           kubernetes.io/os=linux   19d

    NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/virt-api          1/1     1            1           19d
    deployment.apps/virt-controller   2/2     2            2           19d
    deployment.apps/virt-operator     2/2     2            2           19d

    NAME                                         DESIRED   CURRENT   READY   AGE
    replicaset.apps/virt-api-6676df49cc          0         0         0       19d
    replicaset.apps/virt-api-999875d56           1         1         1       19d
    replicaset.apps/virt-controller-546cb985cd   2         2         2       19d
    replicaset.apps/virt-controller-54c7869f6c   0         0         0       19d
    replicaset.apps/virt-operator-6459bcf8c6     2         2         2       19d

    NAME                            AGE   PHASE
    kubevirt.kubevirt.io/kubevirt   19d   Deployed
    ```
10.  Enable Virt-Handler to discover Graphics VFs
     Update KubeVirt custom resource configuration to enable virt-handler to discover graphics VFs on the host. All discovered VFs will be published as *allocatable* resource

     **Update Graphics Device ID in `kubevirt-cr-gfx-sriov.yaml` if not found**
     - Read the Device ID of Intel Graphics Card from Host, Ex: for RPL
         ```sh
         $ cat /sys/devices/pci0000\:00/0000\:00\:02.0/device

         0xa7a0
         ```
     - Add the Device ID in `pciHostDevices` section
         ```yaml
         - pciVendorSelector: "8086:a7a0"
         resourceName: "intel.com/sriov-gpudevice"
         externalResourceProvider: false
         ```

     Apply the YAML changes
     ```sh
     kubectl apply -f manifests/kubevirt-cr-gfx-sriov.yaml
     ```

     **Check for presence of `intel.com/sriov-gpudevices` resource**

     ```sh
     kubectl describe nodes
     ```
     Output:
     ```sh
     Capacity:
         intel.com/sriov-gpudevice:     7
     Allocatable:
         intel.com/sriov-gpudevice:     7
     Allocated resources:
         Resource                       Requests     Limits
         --------                       --------     ------
         intel.com/sriov-gpudevice      0            0
     ```
     > [!Note] 
     > Please wait for all virt-handler pods to complete restarts\
     > The value of **Requests** and **Limits** will increase upon successful resource allocation to running pods/VMs

11.  Install CDI
     ```sh
     kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.60.3/cdi-operator.yaml
     kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.60.3/cdi-cr.yaml
     ```

12.  Install Virt-Plugin
     ```sh
     (
        set -x; cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
     )

     export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

     kubectl krew install virt
     ```
