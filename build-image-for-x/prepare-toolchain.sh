#!/usr/bin/env bash
set -e -x

source default-config

if [[ "$COMPILER_INSTALL_METHOD" == "skip" ]]; then
    echo "Skip install compiler"
elif [[ "$COMPILER_INSTALL_METHOD" == "sources" ]]; then
    . install-compiler-from-sources.sh
elif [[ "$COMPILER_INSTALL_METHOD" == "package" ]]; then
    . install-compiler-from-packages.sh
else
    die "Unknown COMPILER_INSTALL_METHOD"
fi