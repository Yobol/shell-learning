#!/usr/bin/env bash

set -e -x

source default-config

# 使用 install-os-packages.sh 脚本安装依赖包
./install-os-packages.sh prepare

# -n 判断变量是否被赋值：变量被赋值返回 true
if [ -n "$CROSS_PLATFORM" ] ;then
    ./install-os-packages.sh qemu-user-static

    # 相当于 cd docker-multiarch
    pushd docker-multiarch

    # 自定义参数，使用 getopts 接收
    ./update.sh \
     -r "$DOCKER_UBUNTU_REPO" \
     -a "$DOCKER_UBUNTU_ARCH" \
     -v "$DOCKER_UBUNTU_VERSION" \
     -A "$DOCKER_UBUNTU_QEMU_ARCH" \
     -V "$DOCKER_UBUNTU_QEMU_VERSION" \

    #docker run --rm --privileged multiarch/qemu-user-static:register

    # 退回到上一次 pushd 或 cd 命令执行前所在的目录
    popd
fi

mkdir -p /var/cache/ccache
DOCKER_ENV+=" --mount=type=bind,source=/var/cache/ccache,destination=/ccache -e CCACHE_DIR/ccache "
[[ -n "$CONFIG" ]] && DOCKER_ENV="--env=CONFIG"

docker run -t --network=host \
  --mount=type=bind,source=${PROJECT_ROOT},destination="/${PROJECT_NAME}" \
  --workdir="/${PROJECT_NAME}/build-image-for-x" \
  $DOCKER_ENV \
  "${DOCKER_UBUNTU_REPO}:${DOCKER_UBUNTU_ARCH}-${DOCKER_UBUNTU_VERSION}" "jobs/quick-build/run.sh"
