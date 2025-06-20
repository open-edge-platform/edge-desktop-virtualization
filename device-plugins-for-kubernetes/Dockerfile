# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Use a minimal base image
FROM debian:stable-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled binary into the container
COPY device-plugin /app/device-plugin

# Ensure the binary is executable
RUN chmod +x /app/device-plugin

# Run the device plugin
ENTRYPOINT ["/app/device-plugin"]

