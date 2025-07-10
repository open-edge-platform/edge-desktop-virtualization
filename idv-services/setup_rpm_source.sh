#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

sudo cp setup_permissions.sh "$HOME/rpmbuild/SOURCES"
sudo cp intel-idv-services-0.1.tar.gz "$HOME/rpmbuild/SOURCES"

sudo cp intel-idv-services.spec "$HOME/rpmbuild/SPECS/"
