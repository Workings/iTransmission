#!/bin/bash

VERSION=7.46.0

curl -O http://curl.haxx.se/download/curl-${VERSION}.tar.gz
tar xf curl-${VERSION}.tar.gz

(
  export DIST_DIR=`pwd`/out
  export OSL_DIR=$(dirname $(dirname `pwd`))
  cd curl-${VERSION}
  curl -O https://raw.githubusercontent.com/sinofool/build-libcurl-ios/master/build_libcurl_dist.sh
  patch build_libcurl_dist.sh < ../patch-build-script.patch
  chmod +x build_libcurl_dist.sh
  ./build_libcurl_dist.sh openssl
  unset DIST_DIR
)

/bin/cp -rf out/* ../../
