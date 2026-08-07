# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Use a minimal base image
# Pinned version below was published 2026 August 5
FROM debian:stable-slim@sha256:9b9a22fc31229ee7932e2428807260934d18a509da1b680ff001a955f4d4eeb4

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled binary into the container
COPY device-plugin /app/device-plugin

# Ensure the binary is executable
RUN chmod +x /app/device-plugin

# Run the device plugin
ENTRYPOINT ["/app/device-plugin"]
