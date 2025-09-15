# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM debian:stable

# Proxy Configuration
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

# Add entrypoint script for host TTY connection
COPY host-connect.sh /usr/local/bin/

# Install xterm, better fonts, and tools needed for host TTY access in a single layer
# and clean up in the same layer to reduce image size
RUN chmod +x /usr/local/bin/host-connect.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    xterm \
    util-linux \
    fonts-noto \
    fonts-dejavu \
    locales \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Set up locale with UTF-8 support
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    # Configure xterm defaults for better appearance and Unicode support
    mkdir -p /etc/X11/app-defaults && \
    cat > /etc/X11/app-defaults/XTerm <<EOF
XTerm*faceName: DejaVu Sans Mono
XTerm*faceSize: 12
XTerm*renderFont: true
XTerm*utf8: 1
XTerm*locale: true
XTerm*metaSendsEscape: true
XTerm*saveLines: 10000
XTerm*scrollBar: true
XTerm*scrollbar.width: 8
XTerm*foreground: rgb:d9/d9/d9
XTerm*background: rgb:00/00/00
XTerm*cursorColor: rgb:d9/d9/d9
XTerm*cursorBlink: true
EOF

# Set environment variables for UTF-8 support
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Set entrypoint to our connection script that directly connects to host login
ENTRYPOINT ["/usr/local/bin/host-connect.sh"]

# ==============================================
# USAGE
# ==============================================
# To run this container with X11 and host TTY access, use:
#   docker run -it --rm \
#     -e DISPLAY=$DISPLAY \
#     -v /tmp/.X11-unix:/tmp/.X11-unix \
#     -v /dev/pts:/dev/pts:rw \
#     --network=none \
#     --pid=host \
#     --privileged \
#     xterm-docker:latest
#
# Required runtime parameters:
# -e DISPLAY=$DISPLAY              : Passes your X11 display to the container
# -v /tmp/.X11-unix:/tmp/.X11-unix : Mounts the X11 socket directory
# -v /dev/pts:/dev/pts:rw          : Shares the host's TTY devices
# --network=none                   : Disables all network access for the container
# --pid=host                       : Shares the host's process namespace
# --privileged                     : Needed for full host access
