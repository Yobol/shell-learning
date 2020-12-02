#!/usr/bin/env bash

set -e -x

source default-config

./prepare-docker-image-ubuntu.sh

#docker run -it --network=host --name=x-builder \
#  --mount=type=bind,source="${PROJECT_ROOT}/build-image-for-x",destination="/${PROJECT_NAME}" --workdir="/${PROJECT_NAME}" \
#  "${DOCKER_UBUNTU_REPO}:${DOCKER_UBUNTU_ARCH}-${DOCKER_UBUNTU_VERSION}" "jobs/quick-build/run.sh"
