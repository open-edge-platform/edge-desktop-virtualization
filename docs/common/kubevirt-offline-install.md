# Install Kubernetes
K3s is a lightweight Kubernetes distribution suitable for Edge and IoT use cases. This step will setup a single node cluster where the host function as both the server/control plane and the worker node. This step is only required if you don't already have a Kubernetes cluster setup that you can use.
```sh
export K3S_VERSION="v1.32.6+k3s1"
export KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"

curl -sfL https://get.k3s.io | INSTALL_K3S_SELINUX_WARN=true INSTALL_K3S_VERSION=${K3S_VERSION}  sh -s - --disable=traefik --write-kubeconfig-mode=644

found=$(grep -x "source <(kubectl completion bash)" ~/.bashrc 2> /dev/null | wc -l)
if [[ $found -eq 0 ]]; then
    echo "source <(kubectl completion bash)" >> ~/.bashrc
fi

found=$(grep -x "alias k=kubectl" ~/.bashrc 2> /dev/null | wc -l)
if [[ $found -eq 0 ]]; then
    echo "alias k=kubectl" >> ~/.bashrc
fi

found=$(grep -x "complete -F __start_kubectl k" ~/.bashrc 2> /dev/null | wc -l)
if [[ $found -eq 0 ]]; then
    echo "complete -F __start_kubectl k" >> ~/.bashrc
fi

found=$(grep -x "export KUBECONFIG=${KUBECONFIG_PATH}" ~/.bashrc 2> /dev/null | wc -l)
if [[ $found -eq 0 ]]; then
    echo "export KUBECONFIG=${KUBECONFIG_PATH}" >> ~/.bashrc
fi
```


# Kubevirt and Intel Device-Plugin installation using TAR files
This version of Kubevirt is built on release tag v1.5.0 along with GTK library support for enabling Display Virtualization and Intel Graphics SR-IOV patched QEMU version 9.1.0 that supports local display of edge node.

And the Intel Device-Plugin to support it.

## Steps
1.  Ensure Kubernetes is installed and local cluster is running.
2.  Download and copy the latest TAR files of Kubevirt and Device-Plugin from [release](https://github.com/open-edge-platform/edge-desktop-virtualization/releases) to the host system
3.  Extract TAR files
    ```sh
    mkdir -p ~/display-virtualization

    tar -xzvf intel-idv-kubevirt*.tar.gz ~/display-virtualization
    tar -xzvf intel-idv-device-plugin*.tar.gz ~/display-virtualization

    cd ~/display-virtualization/intel-idv-kubevirt*
    zstd -d *.zst

    cd ..
    cd ~/display-virtualization/intel-idv-device-plugin*
    zstd -d *.zst
    ```
4.  Import the images into the container runtime
    ```sh
    cd ~/display-virtualization/intel-idv-kubevirt*
    sudo k3s ctr i import virt-operator.tar
    sudo k3s ctr i import virt-api.tar
    sudo k3s ctr i import virt-controller.tar
    sudo k3s ctr i import virt-handler.tar
    sudo k3s ctr i import virt-launcher.tar
    sudo k3s ctr i import sidecar-shim.tar

    cd ~/display-virtualization/intel-idv-device-plugin*
    sudo k3s ctr i import device-plugin.tar
    sudo k3s ctr i import busybox.tar
    ```
5.  Verify the images are imported correctly
    ```sh
    sudo crictl images | grep localhost

    localhost:5000/sidecar-shim                           v1.5.0_DV           c48d79a700926       51.5MB
    localhost:5000/virt-api                               v1.5.0_DV           025a39d7f7504       28.6MB
    localhost:5000/virt-controller                        v1.5.0_DV           d1cb23d032aa0       27.9MB
    localhost:5000/virt-handler                           v1.5.0_DV           a9bd1a37e2e0c       90.7MB
    localhost:5000/virt-launcher                          v1.5.0_DV           c69ddc6b90387       403MB
    localhost:5000/virt-operator                          v1.5.0_DV           99462ddb3a866       39.8MB
    localhost:5000/device-plugin                          v1                  156ba1fcaf549       21.3MB
    localhost:5000/busybox                                latest              ff7a7936e9306       2.21MB
    ```
6.  Deploy Kubevirt and Device Plugin
    ```sh
    cd ~/display-virtualization/intel-idv-kubevirt*
    kubectl apply -f kubevirt-operator.yaml
    kubectl apply -f kubevirt-cr.yaml

    cd ~/display-virtualization/intel-idv-device-plugin*
    kubectl apply -f intel-idv-device-plugin.yaml
    ```
7.  Verify Deployment
    ```sh
    kubectl get all -A

    NAMESPACE     NAME                                          READY   STATUS    RESTARTS      AGE
    .
    .
    kube-system   pod/device-plugin-q2c2n                       1/1     Running   0             10d
    kubevirt      pod/virt-api-6c66767447-tvqwz                 1/1     Running   0             8d
    kubevirt      pod/virt-controller-599f9b4d86-ffv2b          1/1     Running   0             8d
    kubevirt      pod/virt-controller-599f9b4d86-pt5rn          1/1     Running   0             8d
    kubevirt      pod/virt-handler-hbtsj                        1/1     Running   0             8d
    kubevirt      pod/virt-operator-69cb894b4c-djrzh            1/1     Running   0             8d
    kubevirt      pod/virt-operator-69cb894b4c-jc8sk            1/1     Running   0             8d
    .
    .
    .
    NAMESPACE   NAME                            AGE   PHASE
    kubevirt    kubevirt.kubevirt.io/kubevirt   9d    Deployed
    .
    .
    ```
8.  Enable Virt-Handler to discover Graphics VFs
    Update KubeVirt custom resource configuration to enable virt-handler to discover graphics VFs on the host. All discovered VFs will be published as *allocatable* resource

    **Update Graphics Device ID in `kubevirt-cr.yaml` if not found**
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
    kubectl apply -f manifests/kubevirt-cr.yaml
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

9.  Install CDI - Not required in case of PVC based deployment
    ```sh
    kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.60.3/cdi-operator.yaml
    kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.60.3/cdi-cr.yaml
    ```
