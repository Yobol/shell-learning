#!/usr/bin/env bash

set -e -x

cd "$(dirname $0)"/../..

source default-config

./get-sources.sh
./prepare-toolchain.sh
./install-libraries.sh
./build-normal.sh