#!/bin/bash
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$NUMEXPR_VERSIONS" ]; then
    NUMEXPR_VERSIONS="1.3 1.3.1 1.4 1.4.2 2.0 2.2.2 2.3 2.3.1 2.4 2.4.6 2.5"
fi

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for NUMEXPR in ${NUMEXPR_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        echo "Building numexpr $NUMEXPR for Python $PYTHON"
        # Put numpy version into the wheelhouse to avoid rebuilding
        $PIP wheel -f $WHEELHOUSE -f $MANYLINUX_URL -w tmp "numpy==$np_ver"
        $PIP install -f tmp "numpy==$np_ver"
        # Add numpy to requirements to avoid upgrading numpy version
        $PIP wheel -f tmp -w unfixed_wheels "numpy==$np_ver" "numexpr==$NUMEXPR"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
