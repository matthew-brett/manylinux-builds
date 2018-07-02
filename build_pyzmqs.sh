#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pyzmqs.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pyzmqs.sh
# or:
#    docker run --rm -e PYZMQ_VERSIONS=17.0.0 -e PYTHON_VERSIONS=3.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pyzmqs.sh
set -e
# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh
source ${IO_PATH}/multibuild/library_builders.sh

set -x

PYZMQ_VERSIONS="${PYZMQ_VERSIONS:-16.0.4 17.0.0}"

LIBSODIUM_VERSION="${LIBSODIUM_VERSION:-1.0.16}"
ZMQ_VERSION="${ZMQ_VERSION:-4.2.5}"
export BUILD_PREFIX="${BUILD_PREFIX:-/usr/local}"
# ensure we link real libzmq, not bundled
export ZMQ_PREFIX=$BUILD_PREFIX
# URL may vary, depending on libzmq version
export LIBZMQ_URL=${LIBZMQ_URL:-https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}}

# Build libsodium
build_simple libsodium ${LIBSODIUM_VERSION} https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION} tar.gz

# Build zmq
build_simple zeromq ${ZMQ_VERSION} ${LIBZMQ_URL} tar.gz --with-libsodium

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for PYZMQ in ${PYZMQ_VERSIONS}; do
        $PIP wheel "pyzmq==$PYZMQ" -w unfixed_wheels
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
