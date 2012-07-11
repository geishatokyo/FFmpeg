#!/bin/sh

LIBRTMP_PATH="../librtmp"

set -e

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

if [ -d FFmpeg ]
then
  echo "Found ffmpeg source directory, no need to fetch from git..."
else
  echo "ffmpeg source directory not found"
  exit 1
fi

ARCHS=${ARCHS:-"armv6 armv7 i386"}

for ARCH in $ARCHS
do
    FFMPEG_DIR=ffmpeg-$ARCH
    if [ -d $FFMPEG_DIR ]
    then
      echo "Removing old directory $FFMPEG_DIR"
      rm -rf $FFMPEG_DIR
    fi
    echo "Copying source for $ARCH to directory $FFMPEG_DIR"
    cp -rf ffmpeg $FFMPEG_DIR

    cd $FFMPEG_DIR

    DIST_DIR=$DIST_DIR_BASE-$ARCH
    mkdir -p $DIST_DIR

    case $ARCH in
        armv6)
            CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc"
            SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk"
            CFLAGS="-I$LIBRTMP_PATH/include"
            LDFLAGS="-L$LIBRTMP_PATH/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk/usr/lib/system"
            EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=armv6 --enable-pic"
            EXTRA_CFLAGS="-arch $ARCH"
            EXTRA_LDFLAGS="-arch $ARCH"
            ;;
        armv7)
            CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc"
            SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk"
            CFLAGS="-I$LIBRTMP_PATH/include"
            LDFLAGS="-L$LIBRTMP_PATH/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk/usr/lib/system"
            EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=armv7 --enable-pic"
            EXTRA_CFLAGS="-arch $ARCH"
            EXTRA_LDFLAGS="-arch $ARCH"
            ;;
        i386)
            CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc"
            SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.1.sdk"
            CFLAGS="-I$LIBRTMP_PATH/include"
            LDFLAGS="-L$LIBRTMP_PATH/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.1.sdk/usr/lib/system"
            EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=i386 --enable-pic"
            EXTRA_CFLAGS="-arch $ARCH"
            EXTRA_LDFLAGS="-arch $ARCH"
            ;;
    esac

    echo "Configuring ffmpeg for $ARCH..."

    ./configure \
    --prefix="$DIST_DIR" \
    --disable-doc \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-avdevice \
    --disable-avfilter \
    --disable-bzlib \
    --enable-static \
    --disable-asm \
    \
    --disable-everything \
    --enable-librtmp \
    --enable-decoder=flv \
    --enable-decoder=aac \
    --enable-encoder=flv \
    --enable-encoder=aac \
    --enable-encoder=mov \
    --enable-demuxer=flv \
    --enable-demuxer=mov \
    --enable-muxer=flv \
    --enable-muxer=mov \
    --enable-protocol=rtmp \
    --enable-protocol=file \
    --cc="$CC" \
    --sysroot="$SYSROOT" \
    --extra-cflags="$CFLAGS $EXTRA_CFLAGS" \
    --extra-ldflags="$LDFLAGS $EXTRA_LDFLAGS" \
    $EXTRA_FLAGS

    echo "Installing ffmpeg for $ARCH..."
    make -j 4 && make install

    cd $SCRIPT_DIR

    if [ -d $DIST_DIR/bin ]
    then
      rm -rf $DIST_DIR/bin
    fi
    if [ -d $DIST_DIR/share ]
    then
      rm -rf $DIST_DIR/share
    fi
done

rm -f dist/libavcodec.a dist/libavformat.a dist/libavutil.a

lipo -create dist-armv6/lib/libavcodec.a dist-armv7/lib/libavcodec.a dist-i386/lib/libavcodec.a -output dist/libavcodec.a
lipo -create dist-armv6/lib/libavformat.a dist-armv7/lib/libavformat.a dist-i386/lib/libavformat.a -output dist/libavformat.a
lipo -create dist-armv6/lib/libavutil.a dist-armv7/lib/libavutil.a dist-i386/lib/libavutil.a -output dist/libavutil.a