#!/usr/bin/env bash
set -e -x

source default-config

if [[ "$COMPILER" == "gcc" ]]; then
    if command -v "gcc-${COMPILER_PACKAGE_VERSION}"; then export CC=gcc-${COMPILER_PACKAGE_VERSION} CXX=g++-${COMPILER_PACKAGE_VERSION};
    elif command -v "gcc${COMPILER_PACKAGE_VERSION}"; then export CC=gcc${COMPILER_PACKAGE_VERSION} CXX=g++${COMPILER_PACKAGE_VERSION};
    elif command -v gcc; then export CC=gcc CXX=g++;
    fi
elif [[ "$COMPILER" == "clang" ]]; then
    if command -v "clang-${COMPILER_PACKAGE_VERSION}"; then export CC=clang-${COMPILER_PACKAGE_VERSION} CXX=clang++-${COMPILER_PACKAGE_VERSION};
    elif command -v "clang${COMPILER_PACKAGE_VERSION}"; then export CC=clang${COMPILER_PACKAGE_VERSION} CXX=clang++${COMPILER_PACKAGE_VERSION};
    elif command -v clang; then export CC=clang CXX=clang++;
    fi
else
    die "Unknown compiler specified"
fi

[[ -d "${WORKSPACE}/sources" ]] || die "Run get-sources.sh first"

mkdir -p "${WORKSPACE}/build"
pushd "${WORKSPACE}/build"

# if [[ "${ENABLE_EMBEDDED_COMPILER}" == 1 ]]; then
#     [[ "$USE_LLVM_LIBRARIES_FROM_SYSTEM" == 0 ]] && CMAKE_FLAGS="$CMAKE_FLAGS -DUSE_INTERNAL_LLVM_LIBRARY=1"
#     [[ "$USE_LLVM_LIBRARIES_FROM_SYSTEM" != 0 ]] && CMAKE_FLAGS="$CMAKE_FLAGS -DUSE_INTERNAL_LLVM_LIBRARY=0"
# fi

# cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DENABLE_EMBEDDED_COMPILER=${ENABLE_EMBEDDED_COMPILER} $CMAKE_FLAGS ../sources

# [[ "$BUILD_TARGETS" != 'all' ]] && BUILD_TARGETS_STRING="--target $BUILD_TARGETS"

# cmake --build . $BUILD_TARGETS_STRING -- -j $THREADS

cmake -DCMAKE_INSTALL_PREFIX=/usr/local/clickhouse ../sources

ninja -j8 clickhouse

popd