#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Default values
DEFAULT_VER="v1"
DEFAULT_DOCKER_REPO="127.0.0.1:5000"
DEFAULT_PUSH="false"
VER="$DEFAULT_VER"
DOCKER_REPO="$DEFAULT_DOCKER_REPO"
PUSH="$DEFAULT_PUSH"

# Function to display usage
usage() {
  echo "Usage: $0 [--ver <version>] [--repo <repo>] [--push]"
  echo "  --ver <version>   Specify the version (default: $DEFAULT_VER)"
  echo "  --repo <repo>     Specify the Docker repository (default: $DEFAULT_DOCKER_REPO)"
  echo "  --push            Push the built image to the Docker repository (default: no push)"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ver)
      VER="$2"
      shift 2
      ;;
    --repo)
      DOCKER_REPO="$2"
      shift 2
      ;;
    --push)
      PUSH="true"
      shift
      ;;
    *)
      echo "Error: Unknown argument: $1"
      usage
      ;;
  esac
done

# Check if 'go' is installed
if ! command -v go > /dev/null ; then
  echo "Error: 'go' not found in PATH, is it installed?"
  exit 1
fi

# Build the device plugin
echo "Building the device plugin..."
rm -f device-plugin
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o device-plugin cmd/main.go
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to build the device plugin"
  exit 1
fi

# Build the Docker image
echo "Building the Docker image..."
docker build --no-cache -t "$DOCKER_REPO/mf-device-plugin:$VER" .
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to build the Docker image"
  exit 1
fi

# Push the Docker image if --push is specified
if [[ $PUSH == "true" ]]; then
  echo "Pushing the Docker image to the repository..."
  ! docker push "$DOCKER_REPO/mf-device-plugin:$VER"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to push the Docker image"
    exit 1
  fi
fi

echo "Build successful."
