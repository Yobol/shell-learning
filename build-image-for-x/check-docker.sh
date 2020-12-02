#!/usr/bin/env bash

# -e 若指令返回值不等于 0，则立即退出 shell
# -x 执行指令后，会显示指令及所有的参数
set -e -x

source default-config

# 检查是否已经安装 Docker
# * > /dev/null 丢弃无用输出
command -v docker > /dev/null || die 'You need to install Docker'

# 检查当前用户是否有 docker 的执行权限
# sudo usermod -aG docker $USER => 将当前用户加入 docker 用户组

docker ps > /dev/null || die "You need to have access to Docker: run \"sudo usermod -aG docker $USER && sudo systemctl restart docker\" and relogin"
