# Deployment of Virtual Machines and Sidecar(ConfigMap) using individual helm charts

This directory contains mapped Sidecar and Virtual Machine Deployment charts.
1. Sidecar scripts, patches Libvirt XML with QEMU Commandline parameters inside Virt-Launcher pod.
   - *deployment/discrete/sidecar/[connector].yaml*
2. Virtual Machine deployment Helm charts to run VM on respecitive monitors (HDMI-1, HDMI-2, DP-1 and DP-3) using CDI.
   - *deployment/discrete/helm-win11_[connector]*
3. Virtual Machine deployment Helm charts to run VM on respecitive monitors (HDMI-1, HDMI-2, DP-1 and DP-3) using PVC.
   - *deployment/discrete/pvc/helm-win11_[connector]*

**Mapping of Sidecar script with VM deployment Helm chart**

Each VM has been configured with 3 CPU, 12GB RAM, 60 GB Disk space.\
Refer `deployment/discrete/helm-win11_[connector]/values.yaml` to edit

| VM Name | Monitor  | Sidecar    | VM Helm Chart    | CDI Image Name  | RDP Port | Path to store VM Image (for PVC based)              |
| :-----: | :------: | :--------: | :--------------: | :-------------: | :------: | :-------------------------------------------------: |
| vm1     | HDMI-1   | hdmi1.yaml | helm-win11_hdmi1 | vm1-win11-image | 3390     | /opt/user-apps/vm_imgs/vm1/disk.img                 |
| vm2     | HDMI-2   | hdmi2.yaml | helm-win11_hdmi2 | vm2-win11-image | 3391     | /opt/user-apps/vm_imgs/vm2/disk.img                 |
| vm3     | DP-1     | dp1.yaml   | helm-win11_dp1   | vm3-win11-image | 3392     | /opt/user-apps/vm_imgs/vm3/disk.img                 |
| vm4     | DP-3     | dp3.yaml   | helm-win11_dp3   | vm4-win11-image | 3393     | /opt/user-apps/vm_imgs/vm4/disk.img                 |

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
## 2. Storing VM Images 
### For CDI based deployment, upload VM bootimage to CDI
Ex. for `vm1` the image name in CDI is `vm1-win11-image`

-   Get IP of CDI
    ```sh
    kubectl get service -A | grep cdi-uploadproxy

    NAMESPACE     NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                  AGE
    cdi           cdi-uploadproxy               ClusterIP      10.43.51.68     <none>          443/TCP                  19d
    ```
-   Upload image, use **.qcow2** or **.img**
    ```sh

    kubevirt virt image-upload --uploadproxy-url=https://10.43.51.68 --insecure dv vm1-win11-image --size=100Gi --access-mode=ReadWriteOnce --force-bind --image-path=/home/guest/disk.qcow2 --force-bind
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

### For PVC based deployment
Ex. for `vm1` the image path to keep VM disk image is `/opt/user-apps/vm_imgs/vm1/` as `disk.img`

## 3. Edit Sidecar script to attach USB peripherals to Virtual Machine

Sidecar script or configmap is used to update the Virt-Launcher Pod's libvirt domain XML `qemucommandline` section\
`qemucommandline` section consist of DISPLAY variable, GTK enablement settings, Monitor info and USB Peripherals which are to be passthrough to the particular VM

### Update DISPLAY variable
Open a Terminal on Host system's physical display
```sh
echo $DISPLAY
```
- Output
```
DISPLAY=:0
```
Get the DISPLAY variable from the above output and update in sidecar script

Ex. in *deployment/discrete/sidecar/hdmi1.yaml* `DISPLAY` is set to `:0`
```xml
<qemu:env name='DISPLAY' value=':0'/> 
```

### Monitor ID
Check Monitor's resolution and names of `connected` displays
Open a Terminal on Host system's physical display
```sh
xrandr
```
-   Output:
    ```sh
    Screen 0: minimum 320 x 200, current 7680 x 1080, maximum 16384 x 16384
    HDMI-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 521mm x 293mm
    1920x1080     60.00*+  50.00    59.94
    1600x1200     60.00
    1680x1050     59.88
    1400x1050     59.95
    1600x900      60.00
    1280x1024     75.02    60.02
    1440x900      59.90
    1280x960      60.00
    1280x800      59.91
    1152x864      75.00
    1280x720      60.00    50.00    59.94
    1024x768      75.03    70.07    60.00
    832x624       74.55
    800x600       72.19    75.00    60.32    56.25
    720x576       50.00
    720x480       60.00    59.94
    640x480       75.00    72.81    66.67    60.00    59.94
    720x400       70.08
    HDMI-2 connected 1920x1080+1920+0 (normal left inverted right x axis y axis) 527mm x 296mm
    1920x1080     60.00*+  50.00    59.94
    1680x1050     59.88
    1600x900      60.00
    1280x1024     75.02    60.02
    1280x800      59.91
    1152x864      75.00
    1280x720      60.00    50.00    59.94
    1024x768      75.03    60.00
    832x624       74.55
    800x600       75.00    60.32
    720x576       50.00
    720x480       60.00    59.94
    640x480       75.00    60.00    59.94
    720x400       70.08
    DP-1 connected 1920x1080+3840+0 (normal left inverted right x axis y axis) 521mm x 293mm
    1920x1080     60.00*+  74.92    50.00    59.94
    1600x1200     60.00
    1680x1050     59.95
    1400x1050     59.98
    1280x1024     75.02    60.02
    1440x900      59.89
    1280x960      60.00
    1280x800      59.81
    1152x864      75.00
    1280x720      60.00    50.00    59.94
    1440x576      50.00
    1024x768      75.03    70.07    60.00
    1440x480      60.00    59.94
    832x624       74.55
    800x600       72.19    75.00    60.32    56.25
    720x576       50.00
    720x480       60.00    59.94
    640x480       75.00    72.81    66.67    60.00    59.94
    720x400       70.08
    DP-2 disconnected (normal left inverted right x axis y axis)
    DP-3 connected 1920x1080+5760+0 (normal left inverted right x axis y axis) 521mm x 293mm
    1920x1080     60.00*+  74.99    50.00    59.94
    1600x1200     60.00
    1680x1050     59.88
    1400x1050     59.95
    1280x1024     75.02    60.02
    1440x900      59.90
    1280x960      60.00
    1280x800      59.91
    1152x864      75.00
    1280x720      60.00    50.00    59.94
    1440x576      50.00
    1024x768      75.03    70.07    60.00
    1440x480      60.00    59.94
    832x624       74.55
    800x600       72.19    75.00    60.32    56.25
    720x576       50.00
    720x480       60.00    59.94
    640x480       75.00    72.81    66.67    60.00    59.94
    720x400       70.08
    DP-4 disconnected (normal left inverted right x axis y axis)
    ```
Get the connector names of monitors from the above output and update in sidecar script

Ex. in *deployment/discrete/sidecar/hdmi1.yaml* `connectors.0` is mapped with
```xml
<qemu:arg value='gtk,gl=on,full-screen=on,zoom-to-fit=on,window-close=off,input=on,connectors.0=HDMI-1'/> 
```

### USB Info
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

To attach USB peripherals to VM, edit Sidecar script of respective VM. Ex. VM to run on HDMI-1
```sh
vi deployment/discrete/sidecar/hdmi1.yaml
```
Add line, before `</qemu:commandline>`
```xml
<qemu:arg value='-usb'/> <qemu:arg value='-device'/> <qemu:arg value='usb-host,hostbus=x,hostport=y.z'/>
``` 
where **x** is USB Bus ID, **y.z** are Ports for that device

Ex. in *deployment/discrete/sidecar/hdmi1.yaml* is mapped with
```xml
<qemu:arg value='-usb'/> <qemu:arg value='-device'/> <qemu:arg value='usb-host,hostbus=3,hostport=3.1'/> <qemu:arg value='-usb'/> <qemu:arg value='-device'/> <qemu:arg value='usb-host,hostbus=3,hostport=3.2'/>
```

## 4. Deploy Sidecar
```sh
kubectl apply -f deployment/discrete/sidecar/hdmi1.yaml
```
Output:
```sh
configmap/sidecar-script-hdmi2 configured
```
Accordingly make changes to other sidecar YAML files and deploy.\
To check status
```sh
kubectl get configmaps

NAME                   DATA   AGE
kube-root-ca.crt       1      19d
sidecar-script-dp1     1      15d
sidecar-script-dp3     1      15d
sidecar-script-hdmi1   1      18d
sidecar-script-hdmi2   1      16d
```

## 5. Deploy Virtual Machine
### For CDI based deployment
```sh
cd deployment/discrete/helm-win11_hdmi1
helm install vm1 .
```
### For PVC based deployment
```sh
cd deployment/discrete/pvc/helm-win11_hdmi1
helm install vm1 .
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
win11-vm2-vm   6d4h   Running   10.42.0.106   edgemicrovisortoolkit   True
win11-vm3-vm   6d4h   Running   10.42.0.108   edgemicrovisortoolkit   True
win11-vm4-vm   6d4h   Running   10.42.0.110   edgemicrovisortoolkit   True
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
  cpu                            1875m (11%)       60m (0%)
  memory                         9009904384 (58%)  418257920 (2%)
  ephemeral-storage              4494967296 (28%)  8789934592 (55%)
  hugepages-1Gi                  0 (0%)            0 (0%)
  hugepages-2Mi                  48Gi (100%)       48Gi (100%)
  devices.kubevirt.io/kvm        4                 4
  devices.kubevirt.io/tun        4                 4
  devices.kubevirt.io/vhost-net  4                 4
  intel.com/igpu                 4                 4
  intel.com/sriov-gpudevice      4                 4
  intel.com/udma                 4                 4
  intel.com/usb                  4                 4
  intel.com/vfio                 4                 4
  intel.com/x11                  4                 4
.
.
.
```

## 6. GPU, DV Driver and Windows Cumulative Update Installation
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

