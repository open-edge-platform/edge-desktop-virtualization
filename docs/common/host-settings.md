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

### Check Monitor's resolution and names of connected displays
Open SSH session to the Host system
```sh
DISPLAY=:0 xrandr
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
