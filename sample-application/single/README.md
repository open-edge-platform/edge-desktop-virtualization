# Deployment of Virtual Machines and sidecar using single helm charts

This directory contains VM deployment helm charts consolidated to one, hence deploying one chart will deploy multiple VMs configured.

**Verify Kubevirt, Device-plugin, SR-IOV GPU Passthrough and Hugepage before deploying VM**
```sh
kubectl describe nodes
```
```sh
.
.
.
Capacity:
  cpu:                            16
  devices.kubevirt.io/kvm:        1k
  devices.kubevirt.io/tun:        1k
  devices.kubevirt.io/vhost-net:  1k
  ephemeral-storage:              16348504Ki
  hugepages-1Gi:                  0
  hugepages-2Mi:                  48Gi
  intel.com/igpu:                 1k
  intel.com/sriov-gpudevice:      7
  intel.com/udma:                 1k
  intel.com/usb:                  1k
  intel.com/vfio:                 1k
  intel.com/x11:                  1k
  memory:                         65394012Ki
  pods:                           110
Allocatable:
  cpu:                            16
  devices.kubevirt.io/kvm:        1k
  devices.kubevirt.io/tun:        1k
  devices.kubevirt.io/vhost-net:  1k
  ephemeral-storage:              15903824679
  hugepages-1Gi:                  0
  hugepages-2Mi:                  48Gi
  intel.com/igpu:                 1k
  intel.com/sriov-gpudevice:      7
  intel.com/udma:                 1k
  intel.com/usb:                  1k
  intel.com/vfio:                 1k
  intel.com/x11:                  1k
  memory:                         15062364Ki
  pods:                           110
.
.
.
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource                       Requests          Limits
  --------                       --------          ------
  cpu                            960m (6%)         15m (0%)
  memory                         4648734400 (30%)  238257920 (1%)
  ephemeral-storage              1123741824 (7%)   2197483648 (13%)
  hugepages-1Gi                  0 (0%)            0 (0%)
  hugepages-2Mi                  0 (0%)            0 (0%)
  devices.kubevirt.io/kvm        0                 0
  devices.kubevirt.io/tun        0                 0
  devices.kubevirt.io/vhost-net  0                 0
  intel.com/igpu                 0                 0
  intel.com/sriov-gpudevice      0                 0
  intel.com/udma                 0                 0
  intel.com/usb                  0                 0
  intel.com/vfio                 0                 0
  intel.com/x11                  0                 0
.
.
.
```

Refer `helm/values.yaml` for configurable parameters. Currently this file contains configuration for 4 VMs, of which only VM1 section is enabled by uncomment. Hence deploying by default will start VM1 only

## 1. Upload VM bootimage to CDI Data Volume
Ex. for `vm1` the image name(dataVolumeName) in CDI is `vm1-win11-image`

-   Get IP of CDI
    ```sh
    kubectl get service -A | grep cdi-uploadproxy

    NAMESPACE     NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                  AGE
    cdi           cdi-uploadproxy               ClusterIP      10.43.51.68     <none>          443/TCP                  19d
    ```
-   Upload image, use **.qcow2** or **.img**
    ```sh

    ./virtctl image-upload --uploadproxy-url=https://10.43.51.68 --insecure dv vm1-win11-image --size=100Gi --access-mode=ReadWriteOnce --force-bind --image-path=/home/guest/disk.qcow2 --force-bind
    ```
    To check status
    ```sh
    kubectl get datavolumes.cdi.kubevirt.io
    
    NAME              PHASE       PROGRESS   RESTARTS   AGE
    vm1-win11-image   Succeeded   N/A                   18d
    vm2-win11-image   Succeeded   N/A                   16d
    vm3-win11-image   Succeeded   N/A                   16d
    vm4-win11-image   Succeeded   N/A                   15d
    ```
  
## 2. Edit values.yaml to map USB peripherals through Sidecar script to attach USB peripherals to Virtual Machine

Get the list of USB devices connected to Host machine
```sh
lsusb -t
```
Output:
```sh
/:  Bus 001.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/1p, 480M
/:  Bus 002.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/3p, 20000M/x2
/:  Bus 003.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/12p, 480M
    |__ Port 002: Dev 002, If 0, Class=Hub, Driver=hub/4p, 480M
        |__ Port 001: Dev 004, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 002: Dev 006, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 002: Dev 006, If 1, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 003: Dev 010, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 004: Dev 013, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
    |__ Port 003: Dev 003, If 0, Class=Hub, Driver=hub/4p, 480M
        |__ Port 001: Dev 007, If 0, Class=Human Interface Device, Driver=usbfs, 1.5M
        |__ Port 002: Dev 009, If 0, Class=Human Interface Device, Driver=usbfs, 1.5M
        |__ Port 003: Dev 012, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 004: Dev 016, If 0, Class=Human Interface Device, Driver=usbhid, 1.5M
        |__ Port 004: Dev 016, If 1, Class=Human Interface Device, Driver=usbhid, 1.5M
    |__ Port 005: Dev 005, If 0, Class=Billboard, Driver=[none], 480M
    |__ Port 006: Dev 008, If 0, Class=Vendor Specific Class, Driver=[none], 12M
    |__ Port 007: Dev 011, If 0, Class=Hub, Driver=hub/4p, 480M
        |__ Port 001: Dev 015, If 0, Class=Audio, Driver=[none], 12M
        |__ Port 001: Dev 015, If 1, Class=Audio, Driver=[none], 12M
        |__ Port 001: Dev 015, If 2, Class=Audio, Driver=[none], 12M
        |__ Port 001: Dev 015, If 3, Class=Human Interface Device, Driver=usbhid, 12M
    |__ Port 010: Dev 014, If 0, Class=Wireless, Driver=btusb, 12M
    |__ Port 010: Dev 014, If 1, Class=Wireless, Driver=btusb, 12M
/:  Bus 004.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/4p, 10000M
    |__ Port 002: Dev 002, If 0, Class=Hub, Driver=hub/4p, 5000M
```

To attach USB peripherals (a pair of Keyboard and mouse) to VM, edit `values.yaml` of respective VM. Ex. VM1 to run on HDMI-1
```sh
vi helm/values.yaml
```
Edit 
```yaml
usb:
    host: 'usb-host'
    hostbus_dev1: 'x'
    hostport_dev1: 'y.a'
    hostbus_dev2: 'x'
    hostport_dev2: 'y.b'
```
where **x** is USB Bus ID, **y.a** , **y.b** are ports for the devices

Ex. in *helm/values.yaml* is VM1 is mapped with
```yaml
usb:
    host: 'usb-host'
    hostbus_dev1: '3'
    hostport_dev1: '3.1'
    hostbus_dev2: '3'
    hostport_dev2: '3.2'
```

## 3. Deploy Virtual Machine
```sh
cd helm
helm install vm .
```
Output
```sh
NAME: vm1
LAST DEPLOYED: Wed Apr 16 17:19:33 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```
To check status of VMs running
```sh
kubectl get vmi

NAME           AGE    PHASE     IP            NODENAME                READY
win11-vm1-vm   6d4h   Running   10.42.0.104   edgemicrovisortoolkit   True
```
Now VM will be launched on monitors

To check the status of allocated resources when 4 VMs are running
```sh
kubectl describe nodes

.
.
.
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource                       Requests          Limits
  --------                       --------          ------
  cpu                            960m (6%)         15m (0%)
  memory                         4648734400 (11%)  238257920 (0%)
  ephemeral-storage              1123741824 (7%)   2197483648 (13%)
  hugepages-1Gi                  0 (0%)            0 (0%)
  hugepages-2Mi                  12Gi (25%)        12Gi (25%)
  devices.kubevirt.io/kvm        1                 1
  devices.kubevirt.io/tun        1                 1
  devices.kubevirt.io/vhost-net  1                 1
  intel.com/igpu                 1                 1
  intel.com/sriov-gpudevice      1                 1
  intel.com/udma                 1                 1
  intel.com/usb                  1                 1
  intel.com/vfio                 1                 1
  intel.com/x11                  1                 1
.
.
.
```

## 4. GPU, DV Driver and Windows Cumulative Update Installation
1. Install Windows Cumulative Update.
   - For Windows 10, download [2023-05 Cumulative Update for Windows 10 Version 21H2 for x64-based Systems (KB5026361)](https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2023/05/windows10.0-kb5026361-x64_961f439d6b20735f067af766e1813936bf76cb94.msu)
   - For Windows 11, download [2023-10 Cumulative Update Preview for Windows 11 Version 22H2 for x64-based Systems (KB5031455)](https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e3472ba5-22b6-46d5-8de2-db78395b3209/public/windows11.0-kb5031455-x64_d1c3bafaa9abd8c65f0354e2ea89f35470b10b65.msu)
   - Double-click the msu file to install

2. Download Intel® Graphics Driver Production Driver Version. 
   [GFX-prod-hini-releases_23ww44-ci-master-15089-revenue-pr1015081-ms-attestation-sign-519-RPL-Rx64.zip](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=816432)
   - Extract the zip file
   - Navigate into the install folder and double click on installer.exe to launch the installer
   - Click the “Begin installation button”
   - After the installation has completed, click the “Reboot Required” button to reboot
   - To check the installation, launch the Device manager, expand the Display adapters item in the device list
   - Right click on the graphics device and select “Properties”. Check that the Intel® Graphics version is 31.0.101.5081
    > [!Note]
    > Note: If you see the yellow triangle with exclamation, then please install the driver manually by selecting the 31.0.101.5081 version. 
    > (Right click to update the driver and select the option to point to the main installation directory)

3. Download Windows Zero Copy Drivers Release 1447 - DVServer, DVServerKMD.
   [ZCBuild_1447_MSFT_Signed.zip](https://www.intel.com/content/www/us/en/download/816539/nex-displayvirtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-psamston-lake.html?cache=1708585927)
   - Extract the zip file
   - Search for ‘Windows PowerShell’ and run it as an administrator
   - Enter the following command and when prompted, enter “Y/Yes” to continue
     ```sh
     C:\> Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
     ```
   - Run the command below to install the DVServerKMD and DVServerUMD device drivers. When prompted, enter “[R] Run once” to continue.
     ```sh
     C:\> .\DVInstaller.ps1
     ```
   - Once the driver installation completes, the Windows Guest VM will reboot automatically
   - To check the installation, launch the Device manager, expand the Display adapters item in the device list
   - Right click on the DVServerUMD device and select “Properties”. Check that the DVServerUMD Device Driver version is 4.0.0.1447
   - In Device Manager, expand the System devices item in the device list
   - Right click on the DVServerKMD device and select “Properties”. Check that the DVServerKMD Device Driver version is 4.0.0.1447
    > [!Note]
    > If you encounter DVInstaller.ps1 failure to run due to blocked script, please follow the [link](https://docs.microsoft.com/enus/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell7.2#:~:text=The%20Unblock%2Dfile%20cmdlet%20lets,the%20computer%20from%20untrusted%20files) to unblock

