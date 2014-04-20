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
TBIN=${TOOLCHAIN}/bin
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

declare -A dcheck; dcheck[TOOLCHAIN]=1; dcheck[TBIN]=1; dcheck[ALIB]=1; dcheck[AINC]=1
declare -A xcheck; xcheck[CC]=1; xcheck[LD]=1
declare -A fcheck; fcheck[LGCC]=1

x=0
SEP="[m"
BAD=0
for i in TOOLCHAIN SYSROOT ALIB AINC TBIN LGCC CC LD AR RANLIB CXX LDSHARE CFLAGS; do
    v="$( eval "echo \$$i" )"
    c="[1;30m∅"

    if   [ -n "${dcheck[$i]}" ]; then if [ -d "$v" ]; then c="[1;32mOK"; else c="[31mBAD"; BAD=1; fi
    elif [ -n "${xcheck[$i]}" ]; then if [ -x "$v" ]; then c="[1;32mOK"; else c="[31mBAD"; BAD=1; fi
    elif [ -n "${fcheck[$i]}" ]; then if [ -f "$v" ]; then c="[1;32mOK"; else c="[31mBAD"; BAD=1; fi
    fi

    echo "[$(( x = ( x + 1 ) % 2 ));35m$i$SEP$c$SEP[$x;36m$v[m"

done | column -ts 
[ $BAD -gt 0 ] && exit 1

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
