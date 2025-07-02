Original Author : Byron Marohn
# Launching terminal via keybind with openbox

## Packages needed

```sh
sudo dnf install xterm xterm-resize libutempter
```
> Not available out of box in EMT.

## Download and install the required packages
Aavailable in centos-stream-9, one can download and install it.

```sh
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/x86_64/os/Packages/xterm-366-10.el9.x86_64.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/x86_64/os/Packages/xterm-resize-366-10.el9.x86_64.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/libutempter-1.2.1-6.el9.x86_64.rpm
sudo dnf install libutempter-1.2.1-6.el9.x86_64.rpm xterm-366-10.el9.x86_64.rpm xterm-resize-366-10.el9.x86_64.rpm
```
## Configure openbox to launch xterm when 1control+alt+t` is pressed

```sh
mkdir -p $HOME/.config/openbox
cat <<EOF > $HOME/.config/openbox/rc.xml
<openbox_config xmlns="http://openbox.org/3.6/rc">
  <keyboard>
    <keybind key="A-C-t">
      <action name="Execute">
        <command>xterm</command>
      </action>
    </keybind>
  </keyboard>
</openbox_config>
EOF
```
## Restart openbox by restarting the idv-init-service
```sh
systemctl --user restart idv-init
```

## Launch Terminal
Now you can press `control+alt+t` to launch xterm

## While VM running
If above is done once, before VM pipeline is triggered, this should work without effecting it.

A keyboard needs to be attached to host, can trigger the terminal.
And you can use it on top of the VM, move it around, full-screen, etc. 

## Working images

![Media (4)](https://github.com/user-attachments/assets/80e5ae6d-eeb7-4b10-b7e6-4f521ada7913)

![Media (5)](https://github.com/user-attachments/assets/8245ff7d-c91d-46a8-bd74-28a117b00e3e)

## Dockerize it
TBD

## 
