# Kubevirt installation using TAR files
This version of Kubevirt is built on release tag v1.5.0 along with GTK library support for enabling Display Virtualization and Intel Graphics SR-IOV patched QEMU version 9.1.0 that supports local display of edge node. Hence tagged the version as v1.5.0_DV and is shared as a [Kubevirt TAR](link_to_kubevier_tar)

Also the Device-Plugin has been shared as a [Device-Plugin TAR](link_to_dp_tar) to support enabling Display Virtualization on local display of edge node

## Steps
1.  Ensure Kubernetes is installed and local cluster is running.
2.  Download [Kubevirt TAR](link_to_kubevier_tar) and [Device-Plugin TAR](link_to_dp_tar) to the host system
3.  Extract TAR files
    ```sh
    mkdir -p ~/display-virtualization

    tar -xzvf kubevirt.tar.gz ~/display-virtualization
    tar -xzvf dv-device-plugin.tar.gz ~/display-virtualization

    cd ~/display-virtualization
    ```
4.  Import the images into the container runtime
    ```sh
    sudo ctr -n k8s.io images import sidecar-shim.tar
    sudo ctr -n k8s.io images import virt-api.tar
    sudo ctr -n k8s.io images import virt-controller.tar
    sudo ctr -n k8s.io images import virt-handler.tar
    sudo ctr -n k8s.io images import virt-launcher.tar
    sudo ctr -n k8s.io images import virt-operator.tar

    sudo ctr -n k8s.io images import device-plugin.tar
    sudo ctr -n k8s.io images import busybox.tar
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
    localhost:5000/mf-device-plugin                       v1                  156ba1fcaf549       21.3MB
    localhost:5000/busybox                                latest              ff7a7936e9306       2.21MB
    ```
6.  Deploy Kubevirt and Device Plugin
    ```sh
    kubectl apply -f kubevirt-operator.yaml
    kubectl apply -f kubevirt-cr.yaml
    kubectl apply -f device-plugin.yaml
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
