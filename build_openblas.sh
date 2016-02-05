#!/bin/bash
# Build OpenBLAS librar
set -e

OPENBLAS_VERSION=0.2.15

# Build, install openblas library
curl -sL http://github.com/xianyi/OpenBLAS/archive/v${OPENBLAS_VERSION}.tar.gz > v${OPENBLAS_VERSION}.tar.gz
tar -xzvf v${OPENBLAS_VERSION}.tar.gz
(cd OpenBLAS-${OPENBLAS_VERSION}/ && make DYNAMIC_ARCH=1 USE_OPENMP=0 NUM_THREADS=64 && make PREFIX=/usr/local/ install)

tar cf io/openblas_${OPENBLAS_VERSION}.tgz /usr/local/lib /usr/local/include
