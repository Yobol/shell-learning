#!/usr/bin/env bash
set -e -x

source default-config

if [[ "$SOURCES_METHOD" == "clone" ]]; then
    ./install-os-packages.sh git
    SOURCES_DIR="${WORKSPACE}/sources"
    mkdir -p "${SOURCES_DIR}"
    git clone --recursive --branch "$SOURCES_BRANCH" "$SOURCES_CLONE_URL" "${SOURCES_DIR}"
    pushd "${SOURCES_DIR}"
    git checkout --recurse-submodules "$SOURCES_COMMIT"
    popd
elif [[ "$SOURCES_METHOD" == "local" ]]; then
    # -f, --force                 remove existing destination files
    # -s, --symbolic              make symbolic links instead of hard links
    ln -f -s "${PROJECT_ROOT}/${PROJECT_NAME}" "${WORKSPACE}/sources"
else
    die "Unknown SOURCES_METHOD"
fi
