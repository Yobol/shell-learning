#!/usr/bin/env bash

# set -e -x
# source default-config

# Dispatches package installation on various OS and distributes.

# Which package to install
WHAT=$1

# if the current user is root, the value of EUID is 0.
[[ $EUID -ne 0 ]] && SUDO=sudo

command -v yum && PACKAGE_MANAGER=yum
command -v pkg && PACKAGE_MANAGER=pkg
command -v apt-get && PACKAGE_MANAGER=apt

case $PACKAGE_MANAGER in
    apt)
        case $WHAT in
            clang*)
                $SUDO apt-get install -y "$WHAT" libc++-dev libc++abi-dev
                [[ $(uname -m) == "x86_64" ]] && $SUDO apt-get install -y "${WHAT/clang/lld}" || true
                ;;
            cmake)
                $SUDO apt-get install -y cmake3 || $SUDO apt-get install -y cmake
                ;;
            curl)
                $SUDO apt-get install -y curl
                ;;
            gcc*)
                $SUDO apt-get install -y "$WHAT" "${WHAT/cc/++}"
                ;;
            git)
                $SUDO apt-get install -y git
                ;;
            libicu-dev)
                $SUDO apt-get install -y libicu-dev
                ;;
            libreadline-dev)
                $SUDO apt-get install -y libreadline-dev
                ;;
            llvm-libs*)
                $SUDO apt-get install -y "${WHAT/llvm-libs/liblld}-dev" "${WHAT/llvm-libs/libclang}-dev"
                ;;
            ninja)
                $SUDO apt-get install -y ninja-build
                ;;
            prepare)
                $SUDO apt-get update
                ;;
            qemu-user-static)
                $SUDO apt-get install -y qemu-user-static
                ;;
            *)
                echo "Unknown package"; exit 1;
                ;;
        esac
        ;;
    yum)
        case $WHAT in
            prepare)
                ;;
            curl)
                $SUDO yum install -y curl
                ;;
            *)
                echo "Unknown package"; exit 1;
                ;;
        esac
        ;;
    pkg)
        case $WHAT in
            prepare)
                ;;
            curl)
                $SUDO pkg install -y curl
                ;;
            *)
                echo "Unknown package"; exit 1;
                ;;
        esac
        ;;
esac