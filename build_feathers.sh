#!/bin/bash
# Build feather packages
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_feathers.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_feathers.sh
# or:
#    docker run --rm -e FEATHER_VERSIONS=0.2.0 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_feathers.sh
#
# Make sure numpy and Cython wheels are on the manylinux server or built in the
# $WHEELHOUSE directory first.
set -e

# Manylinux, Python versions
source /io/common_vars.sh

if [ -z "${FEATHER_VERSIONS}" ]; then
    FEATHER_VERSIONS="0.1.0 0.1.1 0.1.2 0.2.0"
fi

# Directory to store wheels
rm_mkdir unfixed_wheels

# Get feather-format source tree
gh-clone wesm/feather
cd feather/python

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PYTHON_INTERPRETER="$(cpython_path $PYTHON)/bin/python"
    PIP="$(cpython_path $PYTHON)/bin/pip"
    PIPI_IO="$PIP install -f $WHEELHOUSE -f $MANYLINUX_URL"

    # Only Python 2.7 and 3.4+ are officially suppoted by the feather project,
    # skip all other Python versions:
    if [ $(lex_ver $PYTHON) -lt $(lex_ver 2.7) ] ; then
        continue
    elif [[ $(lex_ver $PYTHON) -gt $(lex_ver 2.7) && \
            $(lex_ver $PYTHON) -lt $(lex_ver 3.4) ]] ; then
        continue
    fi
    for FEATHER in ${FEATHER_VERSIONS}; do
        $PIPI_IO "numpy==1.9.0"
        $PIPI_IO "cython==0.24"
        echo "Building feather-format $FEATHER for Python $PYTHON"
        git clean -fxd
        git reset --hard
        git checkout "v$FEATHER"
        ln -s ../cpp/src src
        # XXX: $PIP wheel . does not work for this project
        $PYTHON_INTERPRETER setup.py bdist_wheel
        mv dist/*.whl ../../unfixed_wheels
    done
done
cd ../..

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
