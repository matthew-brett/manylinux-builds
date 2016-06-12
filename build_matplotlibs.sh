#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_matplotlibs.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_matplotlibs.sh
# or:
#    docker run --rm -e MATPLOTLIB_VERSIONS=1.10.4 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_matplotlibs.sh
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$MATPLOTLIB_VERSIONS" ]; then
    MATPLOTLIB_VERSIONS="1.3.0 1.3.1 1.4.0 1.4.1 \
        1.4.2 1.4.3 1.5.0 1.5.1"
fi

# Use local freetype for versions which support it
export MPLLOCALFREETYPE=1

# Unicode width
UNICODE_WIDTH=${UNICODE_WIDTH:-32}

source /io/build_mpl_libs.sh

# Directory to store wheels
rm_mkdir unfixed_wheels

# Get matplotlib source tree
gh-clone matplotlib/matplotlib
cd matplotlib

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON $UNICODE_WIDTH)/bin/pip"
    for MATPLOTLIB in ${MATPLOTLIB_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            NUMPY_VERSION=1.9.1
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            NUMPY_VERSION=1.7.2
        else
            NUMPY_VERSION=1.6.2
        fi
        echo "Building matplotlib $MATPLOTLIB for Python $PYTHON"
        git clean -fxd
        git reset --hard
        git checkout "v$MATPLOTLIB"
        $PIP install -f $MANYLINUX_URL "numpy==$NUMPY_VERSION"
        # Add patch for TCL / Tk runtime loading
        patch_file="/io/mpl-tkagg-${MATPLOTLIB}.patch"
        if [ -f $patch_file ]; then
            git apply $patch_file
        fi
        $PIP wheel --no-deps -w ../unfixed_wheels .
    done
done
cd ..

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
