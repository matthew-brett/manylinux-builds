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

source /io/build_mpl_libs.sh

# Build against ancient tcl/tk
yum install -y tk-devel

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for MATPLOTLIB in ${MATPLOTLIB_VERSIONS}; do
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            NUMPY_VERSION=1.9.1
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            NUMPY_VERSION=1.7.2
        else
            NUMPY_VERSION=1.6.2
        fi
        echo "Building matplotlib $MATPLOTLIB for Python $PYTHON"
        $PIP install "numpy==$NUMPY_VERSION"
        $PIP wheel --no-deps -w unfixed_wheels \
            "matplotlib==$MATPLOTLIB"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE

# Remove lib depends on tcl / tk in favor of in-process resolution after
# Tkinter import.
$(shebang_for auditwheel) /io/untcl_wheels.py $WHEELHOUSE/*.whl
