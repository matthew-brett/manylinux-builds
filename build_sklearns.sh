#!/bin/bash
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$SCIKIT_LEARN_VERSIONS" ]; then
    SCIKIT_LEARN_VERSIONS="0.16.0 0.16.1 0.17 0.17.1"
fi

CYTHON_VERSION=0.23.4

# Install blas
get_blas

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for SCIKIT_LEARN in ${SCIKIT_LEARN_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            NUMPY_VERSION=1.9.1
            SCIPY_VERSION=0.16.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            NUMPY_VERSION=1.7.0
            SCIPY_VERSION=0.12.0
        else
            NUMPY_VERSION=1.6.1
            SCIPY_VERSION=0.9.0
        fi
        echo "Building scikit-learn $SCIKIT_LEARN for Python $PYTHON"
        # Put numpy and scipy into the wheelhouse to avoid rebuilding
        $PIP wheel -f $WHEELHOUSE -f $MANYLINUX_URL -w tmp \
            "numpy==$NUMPY_VERSION" "scipy==$SCIPY_VERSION"
        $PIP install -f tmp "numpy==$NUMPY_VERSION" "scipy==$SCIPY_VERSION"
        # Add numpy and scipy  to requirements to avoid upgrading
        # Prevent download of scikit-learn from pypi
        $PIP wheel -f tmp -w unfixed_wheels \
            --no-binary scikit-learn \
            "numpy==$NUMPY_VERSION" \
            "scipy==$SCIPY_VERSION" \
            "scikit-learn==$SCIKIT_LEARN"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
