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

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
EOF

docker build -t "${IMAGE_REPO}:${OS_ARCH}-${OS_VERSION}" .
docker run --rm "${IMAGE_REPO}:${OS_ARCH}-${OS_VERSION}" /bin/bash -ec "echo Hello from Ubuntu!"
