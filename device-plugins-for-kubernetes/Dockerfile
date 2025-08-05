# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Use a minimal base image
# Pinned version below was published 2025 June 30
FROM debian:stable-slim@sha256:7e0b7fe7c6d695d615eabaea8d19adf592a6a9ff3dbd5206d3e31139b9afdfa7

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled binary into the container
COPY device-plugin /app/device-plugin

# Ensure the binary is executable
RUN chmod +x /app/device-plugin

# Run the device plugin
ENTRYPOINT ["/app/device-plugin"]
