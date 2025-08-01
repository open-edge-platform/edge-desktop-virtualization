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

# Enable GPU Virtual Functions
This step is to enable Virtual functions of GPU for VMs to use

#### Create a service to set up VFs at boot time
```
sudo vi /etc/systemd/user/idv-enable-vf.service
```
Add
```
[Unit]
Description=IDV Enable VFs
After=graphical.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStartPost=/bin/bash -c 'set -o pipefail; cd /usr/bin/idv/init && /usr/bin/sudo ./setup_sriov_vfs.sh | systemd-cat -t idv-init-service'
ExecStartPost=/usr/bin/xhost +
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
```