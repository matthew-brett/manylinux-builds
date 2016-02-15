#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_numpies.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_numpies.sh
# or:
#    docker run --rm -e NUMPY_VERSIONS=1.10.4 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_numpies.sh

set -e
if [ -z $PYTHON_VERSIONS ]; then
    PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
fi
if [ -z $NUMPY_VERSIONS ]; then
    NUMPY_VERSIONS="1.6.0 1.6.1 1.6.2 1.7.0 1.7.1 1.7.2 1.8.0 1.8.1 1.8.2 \
        1.9.0 1.9.1 1.9.2 1.9.3 1.10.0 1.10.1 1.10.2 1.10.3 1.10.4"
fi

MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux
CYTHON_VERSION=0.21.2

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

# Install openblas
curl -LO $MANYLINUX_URL/openblas_0.2.15.tgz
tar xf openblas_0.2.15.tgz

# Directory to store wheels
mkdir unfixed_wheels

# Get numpy source tree
git clone https://github.com/numpy/numpy.git
cd numpy

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    /opt/$PYTHON/bin/pip install -f $MANYLINUX_URL "cython==$CYTHON_VERSION"
    for NUMPY in ${NUMPY_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] &&
            [ $(lex_ver $NUMPY) -lt $(lex_ver 1.7) ] ; then
            continue
        fi
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] &&
            [ $(lex_ver $NUMPY) -lt $(lex_ver 1.9) ] ; then
            continue
        fi
        echo "Building numpy $NUMPY for Python $PYTHON"
        git clean -fxd
        git reset --hard
        git checkout "v$NUMPY"
        patch_file="/io/openblas_$NUMPY.patch"
        if [ -f $patch_file ]; then
            git apply $patch_file
        fi
        /opt/${PYTHON}/bin/pip wheel -w ../unfixed_wheels .
    done
done
cd ..

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
