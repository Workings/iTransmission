#!/bin/bash

VERSION=1.0.2e

if [ ! -s openssl-${VERSION}.tar.gz ]; then
  echo "Downloading openssl ${VERSION}"
  curl -O http://www.openssl.org/source/openssl-${VERSION}.tar.gz
fi
if [ ! -d openssl-${VERSION} ]; then
  tar xf openssl-${VERSION}.tar.gz
fi

(
  export DIST_DIR=`pwd`/out
  cd openssl-${VERSION}
  curl https://raw.githubusercontent.com/sinofool/build-openssl-ios/master/build_openssl_dist.sh | bash
  unset DIST_DIR
)

/bin/cp -rf out/* ../../
