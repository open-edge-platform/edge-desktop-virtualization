#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -eE
start_time=$(date +%s)
# Define color variables for readability
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
ENDCOLOR='\e[0m' # Reset to default color

# ------------------- Default Values ------------------------------

# Default tag. This will be the latest EMT release tag.
DEFAULT_TAG=3.0.20251030

# Default image config .json file. If this is NULL, default will be fetched from the repo.
DEFAULT_IDV_JSON_PATH=""
# This will be used only if above is NULL
DEFAULT_IDV_JSON_GIT_FETCH="https://raw.githubusercontent.com/open-edge-platform/edge-desktop-virtualization/refs/heads/emt-dv-iso/emt-dv-iso/idv.json"

# ------------------- Global Variables ----------------------------

# Git repo to build against. This can be any forked repo of EMT as well.
GIT_REPO=https://github.com/open-edge-platform/edge-microvisor-toolkit.git

# Full path of the image config JSON.
IDV_JSON_PATH=$DEFAULT_IDV_JSON_PATH

# If no TAG is provided by user, lets use the default tag
TAG=$DEFAULT_TAG

# Register the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function launch_build() {
    echo -e "${RED}------------------------- Build Details -----------------------------------${ENDCOLOR}"
    echo -e "${BLUE}Current working directory : ${GREEN}$DIR ${ENDCOLOR}"
    echo -e "${BLUE}No. of CPUs on the system : ${GREEN}$(nproc)${ENDCOLOR}"
    echo -e "${BLUE}git repo to be used       : ${GREEN}$GIT_REPO ${ENDCOLOR}"
    echo -e "${BLUE}tag (a release tag)       : ${GREEN}$TAG ${ENDCOLOR}"
    echo -e "${BLUE}image config Json Path    : ${GREEN}$IDV_JSON_PATH ${ENDCOLOR}"
    echo -e "${BLUE}Json git fetch path (if above Json Path is NULL) : ${GREEN}$DEFAULT_IDV_JSON_GIT_FETCH ${ENDCOLOR}"
    echo -e "${RED}--------------------------------------------------------------------------${ENDCOLOR}"

    # clone the emt repo
    echo -e "${BLUE}Cloning the EMT repo @${GREEN}${GIT_REPO}${ENDCOLOR}"
    git clone $GIT_REPO
    cd edge-microvisor-toolkit

    # checkout the required TAG
    echo -e "${BLUE}Checkout tag : ${GREEN}${TAG}${ENDCOLOR}"
    git checkout $TAG

    # pre-requisites
    echo -e "${BLUE}Installing all the pre-requisites${ENDCOLOR}"
    sudo ./toolkit/docs/building/prerequisites-ubuntu.sh
    sudo ln -vsf /usr/lib/go-1.21/bin/go /usr/bin/go
    sudo ln -vsf /usr/lib/go-1.21/bin/gofmt /usr/bin/gofmt
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER

    # build the toolkit
    cd toolkit
    if [[ -z "$IDV_JSON_PATH" ]]; then
        echo -e "${BLUE}JSON input not provided. Hence download the default one.${ENDCOLOR}"
        wget $DEFAULT_IDV_JSON_GIT_FETCH
        cp idv.json ./imageconfigs
    else
        echo -e "${BLUE}JSON input provided is : ${GREEN}$IDV_JSON_PATH${ENDCOLOR}"
        cp $IDV_JSON_PATH ./imageconfigs/idv.json
    fi
    sudo make -j$(nproc) toolchain REBUILD_TOOLS=y VALIDATE_TOOLCHAIN_GPG=n

    # build the iso image
    sudo make iso -j$(nproc) REBUILD_TOOLS=y REBUILD_PACKAGES=n VALIDATE_TOOLCHAIN_GPG=n CONFIG_FILE=./imageconfigs/idv.json

    # copy the generated iso to same parent folder
    cp ../out/images/idv/*.iso ../../.

    echo -e ${GREEN}"Build Successful!"
    echo -e "${BLUE}Generated ISO available at : ${GREEN}$DIR${ENDCOLOR}"
    echo -e ${BLUE}"Available ISO Files : " ${GREEN} $DIR/*.iso ${ENDCOLOR}
}

function cleanup() {
    echo -e "${GREEN}Performing cleanup ${ENDCOLOR}"
    cd $DIR
    sudo rm -rf edge-microvisor-toolkit
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo -e ${BLUE}"Total Build runtime: ${GREEN}$runtime seconds"${ENDCOLOR}
}

while getopts ':t:f:h' opt; do
  case "$opt" in
    t)
      tag_arg="$OPTARG"
      TAG=$tag_arg
      echo "Processing option 't' with '${TAG}' argument"
      ;;

    f)
      file_arg="$OPTARG"
      IDV_JSON_PATH=$(realpath "$file_arg")
      echo "Processing option 'f' with '${IDV_JSON_PATH}' argument"
      ;;

    h)
      echo "Usage: $(basename $0) [-t tag-name] [-f image-config-json-file]"
      exit 0
      ;;

    :)
      echo -e "option requires an argument.\nUsage: $(basename $0) [-t tag-name] [-f image-config-json-file]"
      exit 1
      ;;

    ?)
      echo -e "Invalid command option.\nUsage: $(basename $0) [-t tag-name] [-f image-config-json-file]"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

trap cleanup EXIT
trap cleanup ERR

#---------------------- main ------------------------

launch_build
