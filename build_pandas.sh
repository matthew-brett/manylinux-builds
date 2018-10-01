#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pandas.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=3.5 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pandas.sh
# or:
#    docker run --rm -e PANDAS_VERSIONS=0.23.4 -e PYTHON_VERSIONS=3.5 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pandas.sh
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$PANDAS_VERSIONS" ]; then
    PANDAS_VERSIONS="0.10.0 0.10.1 0.11.0 0.12.0 0.13.0 0.13.1 \
        0.14.0 0.14.1 0.15.0 0.15.1 0.15.2 \
        0.16.0 0.16.1 0.16.2 \
        0.17.0 0.17.1 0.18.0 0.18.1"
fi

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON $UNICODE_WIDTH)/bin/pip"
    for PANDAS in ${PANDAS_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ||
            [ $(lex_ver $PANDAS) -ge $(lex_ver 0.15) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        echo "Building pandas $PANDAS for Python $PYTHON"
        # Put numpy version into the wheelhouse to avoid rebuilding
        $PIP wheel -f $WHEELHOUSE -f $MANYLINUX_URL -w tmp "numpy==$np_ver"
        $PIP install -f tmp "numpy==$np_ver"
        # Add numpy to requirements to avoid upgrading numpy version
        $PIP wheel -f tmp -w unfixed_wheels "numpy==$np_ver" "pandas==$PANDAS"
    done
done

# Delete everything but pandas from wheelhouse
for fn in $(ls unfixed_wheels); do
    if [[ ! "$fn" =~ ^pandas-.* ]]; then
        rm unfixed_wheels/$fn
    fi
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
