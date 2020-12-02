# README

## 加速技巧

> 以 Ubuntu 18.04.5 LTS 为示例。

### proxychains

```shell script
$ sudo apt-get update
$ sudo apt-get install proxychains

$ sudo 'http    172.16.0.249    3128' >> /etc/proxychains.conf

# 使用示例
$ sudo proxychains git clone https://github.com/ClickHouse/ClickHouse.git
$ cd ClickHouse
$ sudo proxychains git submodule update --init --recursive
```

### 镜像源

> sources.list FROM https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/

```
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
```

```shell script
# 备份
$ sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak

$ sudo cp sources.list /etc/apt/sources.list
$ sudo apt-get update
$ sudo apt-get install -y --no-install-recommends ca-certificates

# 使用示例
$ sudo apt-get install vim
```

## 通用

### `setup.sh`

一些经常在项目中使用到的命令。

### `install-os-packages.sh`

给出了可以在不同操作系统上安装软件包的适配框架。

**使用方式**

```shell script
# 更新镜像源
./install-os-packages.sh prepare

# 安装 curl
./install-os-packages.sh curl
```