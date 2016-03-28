#!/bin/bash
# Build scipy packages
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_scipies.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_scipies.sh
# or:
#    docker run --rm -e SCIPY_VERSIONS=0.17.0 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_scipies.sh
#
# Make sure numpy and Cython wheels are on the manylinux server or built in the
# $WHEELHOUSE directory first.
# OpenBLAS should be in $LIBRARIES directory
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

if [ -z "$SCIPY_VERSIONS" ]; then
    SCIPY_VERSIONS="0.9.0 0.10.0 0.10.1 0.11.0 0.12.0 0.12.1 \
        0.13.0 0.13.1 0.13.2 0.13.3 0.14.0 0.14.1\
        0.15.0 0.15.1 0.16.0 0.16.1 0.17.0"
fi

CYTHON_VERSION=0.22.1

# Install blas
get_blas

# Directory to store wheels
rm_mkdir unfixed_wheels

# Get scipy source tree
gh-clone scipy/scipy
cd scipy

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    PIPI_IO="$PIP install -f $WHEELHOUSE -f $MANYLINUX_URL"
    $PIPI_IO "cython==$CYTHON_VERSION"
    for SCIPY in ${SCIPY_VERSIONS}; do
        # Does Python 3.5 need scipy >= 0.16?
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] &&
            [ $(lex_ver $SCIPY) -lt $(lex_ver 0.16) ] ; then
            continue
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] &&
            [ $(lex_ver $SCIPY) -lt $(lex_ver 0.12) ] ; then
            continue
        fi
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ]; then
            $PIPI_IO "numpy==1.9.0"
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ||
            [ $(lex_ver $SCIPY) -ge $(lex_ver 0.17) ] ; then
            $PIPI_IO "numpy==1.7.0"
        else
            $PIPI_IO "numpy==1.6.0"
        fi
        echo "Building scipy $SCIPY for Python $PYTHON"
        git clean -fxd
        git reset --hard
        git checkout "v$SCIPY"
        $PIP wheel -w ../unfixed_wheels .
    done
done
cd ..

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
