#!/bin/bash
# Build OpenBLAS library
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_openblas.sh
# Followed by something like:
#    scp openblas_0.2.15.tgz nipy.bic.berkeley.edu:/home/manylinux
set -e

OPENBLAS_VERSION=0.2.15

# Build, install openblas library
curl -sL http://github.com/xianyi/OpenBLAS/archive/v${OPENBLAS_VERSION}.tar.gz > v${OPENBLAS_VERSION}.tar.gz
tar -xzvf v${OPENBLAS_VERSION}.tar.gz
(cd OpenBLAS-${OPENBLAS_VERSION}/ && make DYNAMIC_ARCH=1 USE_OPENMP=0 NUM_THREADS=64 && make PREFIX=/usr/local/ install)

tar cf io/openblas_${OPENBLAS_VERSION}.tgz /usr/local/lib /usr/local/include
