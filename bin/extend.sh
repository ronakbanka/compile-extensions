#!/bin/sh

set -euo pipefail

BUILDPACK_PATH=$1

echo "-------> Buildpack version $(cat $BUILDPACK_PATH/VERSION)"

if test -d $BUILDPACK_PATH/dependencies; then
  export PATH=$BUILDPACK_PATH/compile-extensions/bin:$PATH
fi
