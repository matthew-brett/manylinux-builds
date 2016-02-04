#!/bin/bash
set -e
PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
NUMPY_VERSIONS="1.6.0 1.6.1 1.6.2 1.7.0 1.7.1 1.7.2 1.8.0 1.8.1 1.8.2 \
    1.9.0 1.9.1 1.9.2 1.9.3 1.10.0 1.10.1 1.10.2 1.10.3 1.10.4"
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

# Install openblas for later numpies
curl -sL http://github.com/xianyi/OpenBLAS/archive/v0.2.15.tar.gz > v0.2.15.tar.gz
tar -xzvf v0.2.15.tar.gz
(cd OpenBLAS-0.2.15/ && make DYNAMIC_ARCH=1 USE_OPENMP=0 NUM_THREADS=64 && make PREFIX=/usr/local/ install)

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
