# https://hub.docker.com/_/scratch
FROM scratch
ADD ubuntu-bionic-core-cloudimg-arm64-root.tar.gz /
# 如果是压缩包的话，ADD 命令会自动解压
ADD cmake-3.16.1.tar.gz /
ENV ARCH=arm64 UBUNTU_SUITE=bionic DOCKER_REPO=multiarch/ubuntu-core
# Add qemu-user-static binary for amd64 builders
ADD x86_64_qemu-aarch64-static.tar.gz /usr/bin
# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
    && echo 'exit 101' >> /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    && dpkg-divert --local --rename --add /sbin/initctl \
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl \
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes

# enable the universe
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list

# 安装 C Compiler
RUN apt-get -y update && apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get -y update
RUN apt-get -y install build-essential gcc-9 g++-9 --fix-missing
RUN apt-get -y install ninja-build --fix-missing

# 编译安装 CMAKE-3
# https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1.tar.gz
RUN cd ./cmake-3.16.1 \
    && ./bootstrap CC=gcc-9 CXX=g++-9 -- -DCMAKE_USE_OPENSSL=OFF \
    && make -j4 \
    && make install \
    && cmake --version

# 编译安裝 Ninja
# https://github.com/ninja-build/ninja/archive/v1.10.1.zip

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
