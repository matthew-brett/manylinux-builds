#!/bin/bash
# Build Cython packages
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_cythons.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_cythons.sh
# or:
#    docker run --rm -e CYTON_VERSIONS=0.23.4 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_cythons.sh
#
# Then upload pages from ``wheelhouse`` to the manylinux server.
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

if [ -z $CYTHON_VERSIONS ]; then
    CYTHON_VERSIONS="0.17 0.17.1 0.17.2 0.17.3 0.17.4 0.18 \
        0.19 0.19.1 0.19.2 0.20 0.20.1  0.20.2 \
        0.21 0.21.1 0.21.2 0.22 0.22.1 \
        0.23 0.23.1 0.23.2 0.23.3 0.23.4"
fi

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for CYTHON in ${CYTHON_VERSIONS}; do
        echo "Building Cython $CYTHON for Python $PYTHON"
        $PIP install "cython==$CYTHON"
        $PIP wheel "cython==$CYTHON" -w unfixed_wheels/
    done
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w $WHEELHOUSE/
done
