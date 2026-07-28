#!/usr/bin/env bash
set -e

ABI="$1"
API="${2:-21}"

if [ -z "$ABI" ]; then
    echo "Usage:"
    echo "  $0 <abi> [api]"
    exit 1
fi

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "ANDROID_NDK_ROOT not found."
    exit 1
fi

ROOT="$(pwd)"
TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"

case "$ABI" in

armeabi-v7a)
    TARGET=armv7a-linux-androideabi
    HOST=arm-linux
    CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp"
    ;;

arm64-v8a)
    TARGET=aarch64-linux-android
    HOST=aarch64-linux
    CFLAGS=""
    ;;

x86)
    TARGET=i686-linux-android
    HOST=i686-linux
    CFLAGS=""
    ;;

x86_64)
    TARGET=x86_64-linux-android
    HOST=x86_64-linux
    CFLAGS=""
    ;;

*)
    echo "Unsupported ABI"
    exit 1
    ;;
esac

export CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
export CXX="$TOOLCHAIN/bin/${TARGET}${API}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export AS="$TOOLCHAIN/bin/llvm-as"
export LD="$TOOLCHAIN/bin/ld"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

export CFLAGS="-D_POSIX_C_SOURCE=200809L $CFLAGS"

PREFIX="$ROOT/output/$ABI"

make distclean || true

rm -f config.h config.mak config.status

./configure \
    --host="$HOST" \
    --sysroot="$TOOLCHAIN/sysroot" \
    --prefix="$PREFIX" \
    --enable-static \
    --enable-shared \
    --enable-pic \
    --disable-cli

# Android bionic không expose fseeko/ftello như glibc
if grep -q "#define fseek fseeko" config.h; then
    sed -i 's/#define fseek fseeko/#define fseek fseek/g' config.h
fi

if grep -q "#define ftell ftello" config.h; then
    sed -i 's/#define ftell ftello/#define ftell ftell/g' config.h
fi

make -j"$(nproc)"
make install