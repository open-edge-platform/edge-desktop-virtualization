# Openbox XTerm Docker Shortcut

This utility provides a containerized version of XTerm with enhanced Unicode support and improved fonts that can be easily launched from an Openbox window manager context menu.

## Overview

The Docker image contains a minimal Debian installation with XTerm, allowing you to run XTerm in an isolated container that connects to a login TTY on your host system. This gives you a proper login shell on the host while leveraging the containerized xterm application. The container follows a strict approach - it either successfully connects to the host login or fails completely without fallbacks. The image includes enhanced font rendering and Unicode support through DejaVu and Noto fonts.

## Building the Image

Use the provided build script to build the Docker image:

```bash
./build-xterm-docker.sh
```

### Build Options

The build script supports the following options:

| Option | Description |
|--------|-------------|
| `--name <image_name>` | Specify a custom image name (default: `localhost:5000/xterm-docker`) |
| `--tag <image_tag>` | Specify a custom image tag (default: `latest`) |
| `--help` | Display help information |


Example:
```bash
./build-xterm-docker.sh --name localhost:5000/xterm-docker --tag latest
```

### Proxy Support

If your environment requires proxy access to download packages, ensure HTTP_PROXY and HTTPS_PROXY (or their lowercase variants) are set prior to calling the `build-xterm-docker.sh` script.

1. Use `HTTP_PROXY` and `HTTPS_PROXY` environment variables if they exist
2. Fall back to `http_proxy` and `https_proxy` if the uppercase versions don't exist

## Running the Container

After building, you can run the container with:

```bash
docker run -it --rm \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/pts:/dev/pts:rw \
  --network=none \
  --pid=host \
  --privileged \
  localhost:5000/xterm-docker:latest
```

### Runtime Parameters

| Parameter | Purpose |
|-----------|---------|
| `-e DISPLAY=$DISPLAY` | Passes your X11 display to the container |
| `-v /tmp/.X11-unix:/tmp/.X11-unix` | Mounts the X11 socket directory |
| `-v /dev/pts:/dev/pts:rw` | Shares the host's TTY devices |
| `--network=none` | Disables all network access for the container |
| `--pid=host` | Shares the host's process namespace |
| `--privileged` | Grants necessary permissions for host TTY access |

## Integrating with Openbox

Add an entry to your Openbox `menu.xml` file (typically found at `~/.config/openbox/menu.xml`):

```xml
<item label="XTerm (Docker)">
    <action name="Execute">
        <command>docker run -it --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/pts:/dev/pts:rw --network=none --pid=host --privileged localhost:5000/xterm-docker:latest</command>
    </action>
</item>
```

Openbox can also be configured to launch the xterm docker image when pressing control+alt+t using the following configuration:

```xml
mkdir -p $HOME/.config/openbox
cat <<EOF > $HOME/.config/openbox/rc.xml
<openbox_config xmlns="http://openbox.org/3.6/rc">
  <keyboard>
    <keybind key="A-C-t">
      <action name="Execute">
        <command>docker run --rm -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/pts:/dev/pts:rw --network=none --pid=host --privileged localhost:5000/xterm-docker:latest</command>
      </action>
    </keybind>
  </keyboard>
</openbox_config>
EOF
```

## Troubleshooting

### X11 Connection Issues

If you encounter connection issues to the X11 server, try:

```bash
xhost +local:docker
```

### Container Exit Immediately

If the container exits immediately, check that:
1. Your X11 server allows connections from the container
2. The DISPLAY environment variable is set correctly
3. The container image is loaded into the docker image store
3. The user launching the container has access to docker (especially for Openbox)

### Host TTY Access Issues

If you have trouble connecting to the host TTY:
1. Make sure you're running Docker with the --privileged flag
2. Verify that `/dev/pts` is properly mounted with read-write permissions
3. Ensure the `--pid=host` flag is included to share the host's process namespace

The container is designed to either work properly or fail completely - there is no fallback to a container shell. This strict behavior ensures you're always connecting to the host system and never accidentally operating in an isolated container environment.
