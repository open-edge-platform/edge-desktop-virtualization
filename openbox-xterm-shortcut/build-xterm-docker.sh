#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Script to build xterm Docker image with proxy support
# This script passes HTTP_PROXY and HTTPS_PROXY environment variables
# to the Docker build process if they exist

# Default values
DEFAULT_IMAGE_NAME="localhost:5000/xterm-docker"
DEFAULT_IMAGE_TAG="latest"
IMAGE_NAME="$DEFAULT_IMAGE_NAME"
IMAGE_TAG="$DEFAULT_IMAGE_TAG"

# Function to display usage
usage() {
  echo "Usage: $0 [--name <image_name>] [--tag <image_tag>]"
  echo "  --name <image_name>   Specify the image name (default: $DEFAULT_IMAGE_NAME)"
  echo "  --tag <image_tag>     Specify the image tag (default: $DEFAULT_IMAGE_TAG)"
  echo "  --help                Display this help message"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown argument: $1"
      usage
      ;;
  esac
done

echo "Building image: $IMAGE_NAME:$IMAGE_TAG"

# Initialize build arguments string
BUILD_ARGS=""

# For HTTP_PROXY: Use $HTTP_PROXY if set, otherwise try $http_proxy
if [ -n "$HTTP_PROXY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTP_PROXY=$HTTP_PROXY"
elif [ -n "$http_proxy" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTP_PROXY=$http_proxy"
fi

# For HTTPS_PROXY: Use $HTTPS_PROXY if set, otherwise try $https_proxy
if [ -n "$HTTPS_PROXY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTPS_PROXY=$HTTPS_PROXY"
elif [ -n "$https_proxy" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg HTTPS_PROXY=$https_proxy"
fi

echo "Building Docker image with the following command:"
echo "docker build $BUILD_ARGS -t $IMAGE_NAME:$IMAGE_TAG ."

if docker build $BUILD_ARGS -t "$IMAGE_NAME:$IMAGE_TAG" .; then
    echo "Build successful! You can run the container with:"
    echo "docker run -it --rm -e DISPLAY=\$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/pts:/dev/pts:rw --network=none --pid=host --privileged $IMAGE_NAME:$IMAGE_TAG"
else
    echo "Build failed!"
    exit 1
fi
