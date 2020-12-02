#!/usr/bin/env bash
set -e -x

source default-config

./check-docker.sh

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

    docker run --rm --privileged multiarch/qemu-user-static:register

    # 退回到上一次 pushd 或 cd 命令执行前所在的目录
    popd
fi