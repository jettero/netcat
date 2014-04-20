#!/bin/bash

ANDROID=4.4.3
PLATFORM=android-9
TARGET=arm-linux-androideabi
HOST=$(uname -sm | tr A-Z\  a-z-)

for i in /usr/local/android/android-ndk-*; do
    if [ -f $i/toolchains/${TARGET}-${ANDROID}/prebuilt/${HOST}/bin/${TARGET}-readelf ]; then
        ANDROID_NDK=$i
        break
    fi
done

if [ ! -d "$ANDROID_NDK" ]; then
    exit "couldn't figure out the NDK to use to get to ANDROID=$ANDROID TARGET=$TARGET HOST=$HOST"
    exit 1
fi

TOOLCHAIN=$ANDROID_NDK/toolchains/${TARGET}-${ANDROID}/prebuilt/${HOST}
SYSROOT=$ANDROID_NDK/platforms/$PLATFORM/arch-arm
ALIB=${SYSROOT}/usr/lib
AINC=${SYSROOT}/usr/include
TBIN=${TOOLCHAIN}/usr/bin
LGCC=${TOOLCHAIN}
CC=${TBIN}/${TARGET}-gcc
LD=${TBIN}/${TARGET}-ld
AR=${TBIN}/${TARGET}-ar
RANLIB=${TBIN}/${TARGET}-ranlib
CXX=${TBIN}/${TARGET}-g++
LDSHARE=$LD

CFLAGS="-Wl,-Bdynamic -Wl,-dynamic-linker,/system/bin/linker -Wl,--gc-sections,-z,nocopyreloc -Wl,--no-undefined"
CFLAGS+=" -Wl,-rpath-link=${ALIB} -L${ALIB} -Wl,-nostdlib --sysroot $SYSROOT $LGCC -lc -lm -I$AINC"

export CC CXX LD LDSHARED AR RANLIB CFLAGS
unset LDFLAGS # not passed to LD, used as a shitty second cflags in the build process

x=0
for i in TOOLCHAIN SYSROOT ALIB AINC TBIN LGCC CC LD AR RANLIB CXX LDSHARE CFLAGS; do
    echo -n "[$(( x = ( x + 1 ) % 2 ));35m$i[m[$x;32m"
    eval "echo \"\$$i[m\""

done | column -ts 

exit

case "${what:-test}" in
    test)
        echo 'int main() { return 0; }' > test.c
        $CC $CFLAGS test.c
        if [ $? = 0 -a -f a.out ]; then
            echo "[1;32mCC seems to work[m"
            exit 0

        else
            echo "[31mCC seems to not work[m"
            exit 1
        fi
        ;;

    full)
        $0 cm
        $0 install
        ;;

    cm|config-make)
        $0 config
        $0 make -j 10
        ;;

    make)
        make $*
        ;;

    clean)
        git clean -dfx
        ;;

    config*)
        $0 clean
        sh ./configure --host=arm-linux $*
        ;;

    *) echo what to do\? ;;
esac
