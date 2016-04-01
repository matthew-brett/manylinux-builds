#!/bin/bash
# Build OpenBLAS library
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_openblas.sh
# Followed by something like:
#    scp openblas_0.2.15.tgz nipy.bic.berkeley.edu:/home/manylinux
set -e

source /io/common_vars.sh

gh-clone xianyi/OpenBLAS
cd OpenBLAS
git checkout "v${OPENBLAS_VERSION}"
git clean -fxd
make DYNAMIC_ARCH=1 USE_OPENMP=0 NUM_THREADS=64 > /dev/null
make PREFIX=/usr/local/ install
tar zcf $LIBRARIES/openblas_${OPENBLAS_VERSION}.tgz /usr/local/lib /usr/local/include
