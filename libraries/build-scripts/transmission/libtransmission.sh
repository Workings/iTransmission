# To configurel the script, define:
#    IPHONE_SDKVERSION: iPhone SDK version (e.g. 8.1)
#
# Then go get the source tar.bz of the libz you want to build, shove it in the
# same directory as this script, and run "./libz.sh". Grab a cuppa. And voila.
#===============================================================================

set -e

: ${LIB_VERSION:=2.84}

# Current iPhone SDK
: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
# Specific iPhone SDK
# : ${IPHONE_SDKVERSION:=8.1}

: ${XCODE_ROOT:=`xcode-select -print-path`}

: ${TARBALLDIR:=`pwd`}
: ${SRCDIR:=`pwd`/src}
: ${IOSBUILDDIR:=`pwd`/ios/build}
: ${PREFIXDIR:=`pwd`/ios/prefix}

LIB_TARBALL=$TARBALLDIR/transmission-$LIB_VERSION.tar.xz
LIB_SRC=$SRCDIR/transmission-${LIB_VERSION}
LIBDIR=$(dirname $(dirname `pwd`))/lib
INCDIR=$(dirname $(dirname `pwd`))/include


#===============================================================================
ARM_DEV_CMD="xcrun --sdk iphoneos"
SIM_DEV_CMD="xcrun --sdk iphonesimulator"

#===============================================================================
# Functions
#===============================================================================

abort()
{
    echo
    echo "Aborted: $@"
    exit 1
}

doneSection()
{
    echo
    echo "================================================================="
    echo "Done"
    echo
}

#===============================================================================

cleanEverythingReadyToStart()
{
    echo Cleaning everything before we start to build...

    rm -rf iphone-build iphonesim-build
    rm -rf $IOSBUILDDIR
    rm -rf $PREFIXDIR

    doneSection
}

#===============================================================================

downloadLib()
{
    if [ ! -s $LIB_TARBALL ]; then
        echo "Downloading transmission ${LIB_VERSION}"
        curl -L -o $LIB_TARBALL http://download.transmissionbt.com/files/transmission-${LIB_VERSION}.tar.xz
    fi

    doneSection
}

#===============================================================================

unpackLib()
{
    [ -f "$LIB_TARBALL" ] || abort "Source tarball missing."

    echo Unpacking transmission into $SRCDIR...

    [ -d $SRCDIR ]    || mkdir -p $SRCDIR
    [ -d $LIB_SRC ] || ( cd $SRCDIR; tar xfj $LIB_TARBALL )
    [ -d $LIB_SRC ] && echo "    ...unpacked as $LIB_SRC"

    doneSection
}

#===============================================================================

buildLibForIPhoneOS()
{
    export TCROOT="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain"
    export LD=${TCROOT}/usr/bin/ld
    export CPP=${TCROOT}/usr/bin/cpp
    export CXX=${TCROOT}/usr/bin/clang++
    export AR=${TCROOT}/usr/bin/ar
    export AS=${TCROOT}/usr/bin/as
    export NM=${TCROOT}/usr/bin/nm
    export CXXCPP=${TCROOT}/usr/bin/cpp
    export RANLIB=${TCROOT}/usr/bin/ranlib
    export CC=${TCROOT}/usr/bin/cc
    export MAKE=/usr/bin/make

    cd $LIB_SRC

    echo Building Library for iPhoneSimulator
    BUILD_DIR=$PREFIXDIR/iphonesim-build
    PLATFORM=iPhoneSimulator
    DEVROOT="$XCODE_ROOT/Platforms/${PLATFORM}.platform/Developer"
    SDKROOT="$XCODE_ROOT/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}$IPHONE_SDKVERSION.sdk"
    export CFLAGS="-O3 -arch i386 -arch x86_64 -isysroot $XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk -mios-simulator-version-min=${IPHONE_SDKVERSION} -Wno-error-implicit-function-declaration -I${BUILD_DIR}/include -I${INCDIR} -I${SDKROOT}/usr/include -pipe -no-cpp-precomp -isysroot ${SDKROOT}"
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS=" -L${BUILD_DIR}/lib -L${LIBDIR} -pipe -no-cpp-precomp -L${SDKROOT}/usr/lib -isysroot ${SDKROOT} -Wl,-syslibroot $SDKROOT"
    ./configure --prefix=$PREFIXDIR/iphonesim-build --disable-shared --enable-static --disable-ipv6 --disable-manual --enable-largefile --disable-nls --enable-lightweight --disable-mac --disable-gtk --with-kqueue --disable-debug
    make
    make install

    mkdir -p $IOSBUILDDIR/x86
    find . -name "*.a" -exec cp "{}" $IOSBUILDDIR/x86 \;

    make clean

    doneSection

    echo Building Library for iPhone
    BUILD_DIR=$PREFIXDIR/iphone-build
    PLATFORM=iPhoneOS
    DEVROOT="$XCODE_ROOT/Platforms/${PLATFORM}.platform/Developer"
    SDKROOT="$XCODE_ROOT/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}$IPHONE_SDKVERSION.sdk"
    export CFLAGS="-O3 -arch armv7 -arch armv7s -arch arm64 -isysroot $XCODE_ROOT/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk -mios-version-min=${IPHONE_SDKVERSION} -I${BUILD_DIR}/include -I${INCDIR} -I${SDKROOT}/usr/include -pipe -no-cpp-precomp -isysroot ${SDKROOT}"
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS=" -L${BUILD_DIR}/lib -L${LIBDIR} -pipe -no-cpp-precomp -L${SDKROOT}/usr/lib -L${DEVROOT}/usr/lib -isysroot ${SDKROOT} -Wl,-syslibroot $SDKROOT"
    ./configure --prefix=$PREFIXDIR/iphone-build --host arm-apple-darwin --disable-shared --enable-static --disable-ipv6 --disable-manual --enable-largefile --disable-nls --enable-lightweight --disable-mac --disable-gtk --with-kqueue --disable-debug
    make
    make install

    mkdir -p $IOSBUILDDIR/arm
    find . -name "*.a" -exec cp "{}" $IOSBUILDDIR/arm \;

    make clean

    doneSection
}

#===============================================================================

scrunchAllLibsTogether()
{
    echo "Combining Libraries Together"
    cd $IOSBUILDDIR/arm

    mkdir -p ${LIBDIR}
    for lib in *.a; do
        $ARM_DEV_CMD lipo -create ../x86/${lib} ../arm/${lib} -output ${LIBDIR}/${lib}
    done

    echo "Copying Headers"

    mkdir -p ${INCDIR}/libtransmission
    find $LIB_SRC/libtransmission -name "*.h" -exec cp "{}" ${INCDIR}/libtransmission \;

    doneSection
}

function do_unset {
    unset DEVROOT
    unset SDKROOT
    unset LD
    unset CPP
    unset CXX
    unset AR
    unset AS
    unset NM
    unset CXXCPP
    unset RANLIB
    unset CC
    unset CFLAGS
    unset LDFLAGS
    unset PREFIX_DIR
    unset COMMON_OPTIONS
}

#===============================================================================
# Execution starts here
#===============================================================================

mkdir -p $IOSBUILDDIR

# cleanEverythingReadyToStart #may want to comment if repeatedly running during dev

echo "LIB_VERSION:       $LIB_VERSION"
echo "LIB_SRC:           $LIB_SRC"
echo "IOSBUILDDIR:       $IOSBUILDDIR"
echo "PREFIXDIR:         $PREFIXDIR"
echo "IPHONE_SDKVERSION: $IPHONE_SDKVERSION"
echo "XCODE_ROOT:        $XCODE_ROOT"
echo "LIBDIR:            $LIBDIR"
echo "INCDIR:            $INCDIR"
echo

downloadLib
unpackLib
buildLibForIPhoneOS
scrunchAllLibsTogether
do_unset

echo "Completed successfully"

#===============================================================================
