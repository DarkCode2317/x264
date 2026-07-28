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
    TARGET=armv7a-linux
    HOST=arm-linux-androideabi
    EXTRA="--extra-cflags='-march=armv7-a -mfpu=neon -mfloat-abi=softfp'"
    export CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp"
    ;;

arm64-v8a)
    TARGET=aarch64-linux-android
    HOST=aarch64-linux
    EXTRA=""
    ;;

x86)
    TARGET=i686-linux-android
    HOST=i686-linux
    EXTRA=""
    ;;

x86_64)
    TARGET=x86_64-linux-android
    HOST=x86_64-linux
    EXTRA=""
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

# Force configure detect Android libc correctly
export ac_cv_func_fseeko=no
export ac_cv_func_ftello=no

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

make -j"$(nproc)"
make install