#!/bin/bash
set -e
PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
PYZMQ_VERSIONS="14.0.1 14.1.0 14.1.1 14.2.0 14.3.0 14.3.1 \
    14.4.0 14.4.1 14.5.0 14.6.0 14.7.0 15.0.0 15.1.0 15.2.0"
LIBSODIUM_VERSION=1.0.8
ZMQ_VERSION=4.1.4

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

function build_archive {
    local pkg_root=$1
    local url=$2
    curl -LO $url/${pkg_root}.tar.gz
    tar zxf ${pkg_root}.tar.gz
    (cd $pkg_root && ./configure && make && make install)
    rm -rf $pkg_root
}

# Build libsodium
build_archive libsodium-${LIBSODIUM_VERSION} https://download.libsodium.org/libsodium/releases

# Build zmq
build_archive zeromq-${ZMQ_VERSION} http://download.zeromq.org

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP=/opt/$PYTHON/bin/pip
    for PYZMQ in ${PYZMQ_VERSIONS}; do
        $PIP wheel "pyzmq==$PYZMQ" -w unfixed_wheels
    done
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
