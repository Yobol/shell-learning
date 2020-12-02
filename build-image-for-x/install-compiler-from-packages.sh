#!/usr/bin/env bash
set -e -x

source default-config

# TODO Install from PPA on older Ubuntu

./install-os-packages.sh "${COMPILER}-${COMPILER_PACKAGE_VERSION}"
