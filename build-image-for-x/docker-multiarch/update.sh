#!/usr/bin/env bash
set -e -x

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "r:a:v:A:V:" opt; do
    case "$opt" in
    r)  IMAGE_REPO=$OPTARG
        ;;
    a)  OS_ARCH=$OPTARG
        ;;
    v)  OS_VERSION=$OPTARG
        ;;
    A)  QEMU_ARCH=$OPTARG
        ;;
    V)  QEMU_VERSION=$OPTARG
        ;;
    *)
        ;;
    esac
done

OS_BASE_URL="https://partner-images.canonical.com/core/$OS_VERSION"
OS_TAR_BASE="ubuntu-$OS_VERSION-core-cloudimg-$OS_ARCH"
OS_TAR_NAME="$OS_TAR_BASE-root.tar.gz"

QEMU_BASE_URL="https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}"
QEMU_TAR_BASE="x86_64_qemu-${QEMU_ARCH}"
QEMU_TAR_NAME="${QEMU_TAR_BASE}-static.tar.gz"

# install qemu-user-static
# WGET Help
#  -v,  --verbose                   be verbose (this is the default)
#  -nv, --no-verbose                turn off verboseness, without being quiet
#       --report-speed=TYPE         output bandwidth as TYPE.  TYPE can be bits
#  -N,  --timestamping              don't re-retrieve files unless newer than
#                                     local
#       --no-if-modified-since      don't use conditional if-modified-since get
#                                     requests in timestamping mode
#       --no-use-server-timestamps  don't set the local file's timestamp by
#                                     the one on the server
#  -S,  --server-response           print server response
#       --spider                    don't download anything
if [ -n "${QEMU_ARCH}" ]; then
    if [ ! -f "${QEMU_TAR_NAME}" ]; then
        wget -nv -N "${QEMU_BASE_URL}/${QEMU_TAR_NAME}"
    fi
    tar -xvf "${QEMU_TAR_NAME}" -C "${ROOT}/usr/bin/"
fi

# get the image
if \
    wget -nv -N --spider "${OS_BASE_URL}/current" \
    && wget -nv -N --spider "${OS_BASE_URL}/current/${OS_TAR_NAME}" \
    ; then
        OS_BASE_URL+="/current"
fi
wget -nv -N "${OS_BASE_URL}/"{{MD5,SHA{1,256}}SUMS{,.gpg},"${OS_BASE_URL}.manifest",'unpacked/build-info.txt'} || true
wget -nv -N "${OS_BASE_URL}/${OS_TAR_NAME}"

# check checksum
if [ -f SHA256SUMS ] ;then
    # sha256sum 用于计算文件的 sha256 哈希值
    # cut:
    #   -d' ' 表示以 空格 字符分割输入值
    #   -f1   表示选择第一列作为输出值
    sha256sum="$(sha256sum "$OS_TAR_NAME" | cut -d' ' -f1)"
    if ! grep -q "$sha256sum" SHA256SUMS; then # 如果 sha256sum 不存在于 SHA256SUM 文件
        echo >&2 "error: \"${OS_TAR_NAME}\" has invalid SHA256" # echo >&2 表示将输出重定向到 stderr 中
        exit 1
    fi
fi

if [ -f Dockerfile ] ;then
    rm -f Dockerfile
fi

cat >> Dockerfile <<-EOF
# https://hub.docker.com/_/scratch
FROM scratch
ADD $OS_TAR_NAME /
# 如果是压缩包的话，ADD 命令会自动解压
ADD cmake-3.16.1.tar.gz /
# ADD ninja-1.10.1.zip /
ENV ARCH=${OS_ARCH} UBUNTU_SUITE=${OS_VERSION} DOCKER_REPO=${IMAGE_REPO}
EOF

# add qemu-user-static binary
if [ -n "${QEMU_ARCH}" ]; then
    cat >> Dockerfile <<EOF
# Add qemu-user-static binary for amd64 builders
ADD ${QEMU_TAR_NAME} /usr/bin
EOF
fi

cat >> Dockerfile <<-EOF
# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d \\
    && echo 'exit 101' >> /usr/sbin/policy-rc.d \\
    && chmod +x /usr/sbin/policy-rc.d \\
    && dpkg-divert --local --rename --add /sbin/initctl \\
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl \\
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl \\
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \\
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \\
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \\
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \\
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \\
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes

# enable the universe
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list

# 参考 https://www.cnblogs.com/gentlemanhai/p/11961326.html
# 包管理器安装 C Compiler
RUN apt-get -y update && apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get -y update
RUN apt-get -y install build-essential gcc-9 g++-9 --fix-missing
# 源码编译安装 C Compiler

# 源码编译安装 CMAKE-3
# https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1.tar.gz
RUN cd ./cmake-3.16.1 \\
    && ./bootstrap CC=gcc-9 CXX=g++-9 -- -DCMAKE_USE_OPENSSL=OFF \\
    && make -j4 \\
    && make install \\
    && cmake --version

# 包管理器安装 Ninja
RUN apt-get -y install ninja-build --fix-missing
# 源码编译安裝 Ninja
# https://github.com/ninja-build/ninja/archive/v1.10.1.zip
# RUN apt-get -y install python
# RUN cd ./ninja-1.10.1 && ./configure.py --bootstrap && ninja --version

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
EOF

docker build -t "${IMAGE_REPO}:${OS_ARCH}-${OS_VERSION}" .
docker run --rm "${IMAGE_REPO}:${OS_ARCH}-${OS_VERSION}" /bin/bash -ec "echo Hello from Ubuntu!"
