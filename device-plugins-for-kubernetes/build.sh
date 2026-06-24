#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Default values
DEFAULT_VER="v1.1"
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
if ! CGO_ENABLED=0 GOOS=linux GOARCH=amd64 BUILD_VERSION=$VER go build -o device-plugin cmd/main.go; then
  echo "Error: Failed to build the device plugin"
  exit 1
fi

# Build the Docker image
echo "Building the Docker image..."
if ! docker build --no-cache -t "$DOCKER_REPO/intel-idv-device-plugin:$VER" .; then
  echo "Error: Failed to build the Docker image"
  exit 1
fi

# Push the Docker image if --push is specified
if [[ $PUSH == "true" ]]; then
  echo "Pushing the Docker image to the repository..."
  if ! docker push "$DOCKER_REPO/intel-idv-device-plugin:$VER"; then
    echo "Error: Failed to push the Docker image"
    exit 1
  fi
fi

# Update the deployment manifest with the newly built image version
perl -p -i -e "s|image:.*intel-idv-device-plugin:.*$|image: '$DOCKER_REPO/intel-idv-device-plugin:$VER'|g" deploy/manifests/intel-idv-device-plugin.yaml
perl -p -i -e "s|repository:.*$|repository: $DOCKER_REPO/intel-idv-device-plugin|g" deploy/helm/intel-idv-device-plugin/values.yaml
perl -p -i -e "s|tag:.*$|tag: \"$VER\"|g" deploy/helm/intel-idv-device-plugin/values.yaml

echo "Build successful."
