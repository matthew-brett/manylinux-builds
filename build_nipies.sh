#!/bin/bash
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$NIPY_VERSIONS" ]; then
    NIPY_VERSIONS="0.4.0"
fi

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for NIPY in ${NIPY_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        echo "Building nipy $NIPY for Python $PYTHON"
        $PIP install "numpy==$np_ver"
        # Add numpy to requirements to avoid upgrading numpy version
        $PIP wheel --no-deps -w unfixed_wheels "nipy==$NIPY"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
