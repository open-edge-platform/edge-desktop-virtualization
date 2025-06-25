#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# These contents may have been developed with support from one or more
# Intel-operated generative artificial intelligence solutions.

extensions_file="/usr/share/X11/xorg.conf.d/10-extensions.conf"
serverflags_file="/usr/share/X11/xorg.conf.d/10-serverflags.conf"

# Disable DPMS
if [ ! -f "$extensions_file" ]; then
    sudo touch "$extensions_file"

    sudo bash -c 'cat << EOF > '${extensions_file}'
Section "Extensions"
    Option "DPMS" "false"
EndSection
EOF'
else
  if ! grep -q "DPMS" "${extensions_file}"; then
    sudo sed -i '$a\
    Section "Extensions"\
        Option "DPMS" "false"\
    EndSection' "$extensions_file"
  fi
fi

# Disable screen blanking and timeouts
if [ ! -f "$serverflags_file" ]; then
    sudo touch "$serverflags_file"

    sudo bash -c 'cat << EOF > '${serverflags_file}'
Section "ServerFlags"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
    Option "BlankTime"   "0"
EndSection
EOF'
else
  if ! grep -q "StandbyTime" "${serverflags_file}"; then
    sudo sed -i '$a\
    Section "ServerFlags"\
      Option "StandbyTime" "0"\
      Option "SuspendTime" "0"\
      Option "OffTime"     "0"\
      Option "BlankTime"   "0"\
    EndSection' "$serverflags_file"
  fi
fi
