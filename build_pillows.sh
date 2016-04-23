#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pillows.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pillows.sh
# or:
#    docker run --rm -e PILLOW_VERSIONS=3.2 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_pillows.sh
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$PILLOW_VERSIONS" ]; then
    PILLOW_VERSIONS="1.7.6 1.7.7 1.7.8 2.1.0 2.5.1 2.6.0 2.6.1 2.9.0 3.0 3.1.0 3.1.1 3.1.2 3.2"
fi

source /io/library_builders.sh
build_libpng
build_jpeg
build_tiff
build_openjpeg
build_lcms2
build_libwebp

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for PILLOW in ${PILLOW_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] &&
            [ $(lex_ver $PILLOW) -lt $(lex_ver 2) ] ; then
            continue
        fi
        echo "Building pillow $PILLOW for Python $PYTHON"
        $PIP wheel --no-deps -w unfixed_wheels \
            "pillow==$PILLOW"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
