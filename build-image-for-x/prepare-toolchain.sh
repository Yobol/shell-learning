#!/usr/bin/env bash
set -e -x

source default-config

if [[ "$COMPILER_INSTALL_METHOD" == "packages" ]]; then
    . install-compiler-from-packages.sh
elif [[ "$COMPILER_INSTALL_METHOD" == "sources" ]]; then
    . install-compiler-from-sources.sh
elif [[ "$COMPILER_INSTALL_METHOD" == "skip" ]]; then
    echo "Skip install compiler"
else
    die "Unknown COMPILER_INSTALL_METHOD"
fi

#xfy# ./install-os-packages.sh cmake
#xfy# ./build-cmake-from-sources.sh
./install-os-packages.sh ninja