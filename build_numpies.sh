#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_numpies.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_numpies.sh
# or:
#    docker run --rm -e NUMPY_VERSIONS=1.10.4 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_numpies.sh

set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

if [ -z "$NUMPY_VERSIONS" ]; then
    NUMPY_VERSIONS="1.6.0 1.6.1 1.6.2 1.7.0 1.7.1 1.7.2 1.8.0 1.8.1 1.8.2 \
        1.9.0 1.9.1 1.9.2 1.9.3 1.10.0 1.10.1 1.10.2 1.10.3 1.10.4"
fi

CYTHON_VERSION=0.21.2

# Get blas / lapack
get_blas

# Directory to store wheels
rm_mkdir unfixed_wheels

# Get numpy source tree
gh-clone numpy/numpy
cd numpy

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    $PIP install -f $WHEELHOUSE -f $MANYLINUX_URL "cython==$CYTHON_VERSION"
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
        $PIP wheel -w ../unfixed_wheels .
    done
done
cd ..

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
