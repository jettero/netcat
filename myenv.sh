#!/bin/bash

TOOLCHAIN=/usr/local/android/android-ndk-r6/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86
ANDROID=/usr/local/android/android-ndk-r6/platforms/android-9/arch-arm/usr
ALIB=${ANDROID}/lib
AINC=${ANDROID}/include
TBIN=${TOOLCHAIN}/bin
TARGET=arm-linux-androideabi
CC=${TBIN}/${TARGET}-gcc
LD=${TBIN}/${TARGET}-ld
AR=${TBIN}/${TARGET}-ar
RANLIB=${TBIN}/${TARGET}-ranlib
CXX=${TBIN}/${TARGET}-g++
LDSHARE=$LD

LDFLAGS="-Bdynamic -dynamic-linker /system/bin/linker --gc-sections -z nocopyreloc --no-undefined -rpath-link=${ALIB} -L${ALIB} -nostdlib ${ALIB}/crtend_android.o ${ALIB}/crtbegin_dynamic.o ${TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.4.3/libgcc.a -lc -lm"
CFLAGS="-Wl,-Bdynamic -Wl,-dynamic-linker,/system/bin/linker -Wl,--gc-sections,-z,nocopyreloc -Wl,--no-undefined -Wl,-rpath-link=${ALIB} -L${ALIB} -Wl,-nostdlib --sysroot /usr/local/android/android-ndk-r6/platforms/android-9/arch-arm ${TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.4.3/libgcc.a -lc -lm -I$ANDROID/include"

unset LDFLAGS # this apparently confuses configure scripts and isn't actually passed to LD, but instead added to the end of CC
export CC CXX LD LDSHARED AR RANLIB CFLAGS LDFLAGS

what=$1
shift
case "$what" in

    test)
        echo 'int main() { return 0; }' > test.c \
            && $CC $CFLAGS test.c \
            && (file a.out | hi . purple)\
            && (echo seems to work | hi . lime)
        ;;

    myd)
        [ ! -f Makefile ] && $0 config
        $0 install
        ssh pevo /data/local/bin/nc -d -v -v -v -v voltar.org 80
        ;;

    install)
        [ ! -f Makefile ] && $0 config
        [ ! -e src/netcat ] && $0 make -j 10
        scp src/netcat pevo:/data/local/bin/nc
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
