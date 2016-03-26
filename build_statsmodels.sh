#!/bin/bash
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$STATSMODELS_VERSIONS" ]; then
    STATSMODELS_VERSIONS="0.6.0 0.6.1"
fi

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for STATSMODELS in ${STATSMODELS_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        else
            np_ver=1.7.0
        fi
        echo "Building statsmodels $STATSMODELS for Python $PYTHON"
        # Put numpy version into the wheelhouse to avoid rebuilding
        $PIP wheel -f $WHEELHOUSE -f $MANYLINUX_URL -w tmp "numpy==$np_ver" scipy pandas cython
        $PIP install -f tmp "numpy==$np_ver"
        # Add numpy to requirements to avoid upgrading numpy version
        $PIP wheel -f tmp -w unfixed_wheels "numpy==$np_ver" "statsmodels==$STATSMODELS"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
