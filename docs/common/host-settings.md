# Setup Hugepages
Set up Hugepages with pagesize 2 MB.

#### Calculation of Hugepage size to set
**Ex.** For 4 VMs deployment with each VM's RAM configured to **12 GB**.\
Total Hugepage size required: **12 GB * 4 = 48 GB = 49152 MB**.\
Since pagesize is 2 MB, hugepage to set here: **49152 / 2 = 24576 MB**.

#### Create a service to set up these hugepages at boot time
```sh
sudo vi /etc/systemd/system/hugepages.service
```
Add
```
[Unit]
Description=Configure Hugepages
Before=k3s.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo $(( 24576 )) | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'

[Install]
WantedBy=multi-user.target
```

#### Enable and start the service, which will configure the hugepages and exit.
```
sudo systemctl daemon-reload
sudo systemctl enable hugepages.service
sudo systemctl start hugepages.service
```

#### Check that hugepages were configured
```
sudo cat /proc/meminfo | grep -i hugepages
```
```
HugePages_Total:   24576
HugePages_Free:    24576
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
```

# Set permissions to USB devices
To use USB peripherals connected to Host machine with Virtual machines

#### Check if user `qemu` exist in the system
```
grep qemu /etc/passwd
```
```
qemu:x:107:107:qemu user:/:/sbin/nologin
```
If not, add the user `qemu`
```
sudo useradd -s /usr/sbin/nologin qemu
```

#### Create a udev rule that will automatically give the user `qemu` access to them
```
sudo vi /etc/udev/rules.d/99-usb-qemu.rules
```
Add
```
ACTION=="add", SUBSYSTEM=="usb", MODE="0664", GROUP="qemu", OWNER="qemu"
```
Apply changes
```
sudo udevadm control --reload-rules
sudo udevadm trigger
```
#### Unplug and re-plug the USB devices you plan to attach to VMs, then check the permissions are set correctly:
```
ls -alR /dev/bus/usb/003/
```
```
...
crw-rw-r--. 1 qemu qemu 189, 8 May 15 22:14 009
...
```

# Display setup

This has been taken care by [IDV Service](../../idv-services/README.md)

#### Disable DPMS and screen blanking on the X Window System

-   DPMS Disable
    ```sh
    sudo vi /usr/share/X11/xorg.conf.d/10-extensions.conf
    ```
    Add
    ```conf
    Section "Extensions"
        Option "DPMS" "false"
    EndSection
    ```

-   Disable Screen Blanking and Timeouts
    ```sh
    sudo vi /usr/share/X11/xorg.conf.d/10-serverflags.conf
    ```
    Add
    ```conf
    Section "ServerFlags"
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime"     "0"
        Option "BlankTime"   "0"
    EndSection
    ```


#### Create a service to autostart the X server
```sh
sudo vi /etc/systemd/system/x.service
```
Add
```
[Unit]
Description=Launch X server at startup
After=network.target
Before=k3s.service

[Service]
Type=simple
ExecStart=/usr/bin/X

[Install]
WantedBy=graphical.target
```

Enable and start the service. You should now see a black screen on the monitors.
**NOTE: When you reboot the machine, you will end up with a black screen, because X is running. To access the console, try `control+alt+f3`.** To return to X, switch back with `control-alt-f2`. If X is not currently the active display, the VMs will not boot, and will error with "SyncVMI failed".
```
sudo systemctl daemon-reload
sudo systemctl enable x.service
sudo systemctl start x.service
```

#### Start Openbox Window Manager to scale applications to full-screen - Needed for EMT
> [!Note]
> This is needed if VM doesn't scale to full-screen after launching.
> Perform this step before starting VM.

-   To start Openbox Window Manager
    ```sh
    DISPLAY=:0 openbox &
    ```
    **Now you can see a cursor (usually on Primary Display: HDMI-1)**

# Troubleshooting

## USB hotplug - WIP