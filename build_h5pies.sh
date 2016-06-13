#!/bin/bash
# Build h5py wheels
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_h5pies.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_h5pies.sh
# or maybe:
#    docker run --rm -e H5PY_VERSIONS=2.6.0 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_h5pies.sh
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

if [ -z "$H5PY_VERSIONS" ]; then
    H5PY_VERSIONS="2.2.0 2.2.1 2.3.0 2.3.1 2.4.0 2.5.0 2.6.0"
fi

source /io/common_vars.sh

# Unicode width
UNICODE_WIDTH=${UNICODE_WIDTH:-32}

CYTHON_VERSION=0.22.1
HDF5_VERSION_1=1.8.3
HDF5_VERSION_2=1.8.16

function rm_archive {
    # Remove files listed in archive contents
    tar tzf $1 | grep -v "/$" | xargs rm
}

# Paths to library archives
HDF_TGZ1=$LIBRARIES/hdf5-${HDF5_VERSION_1}-${COMPILER_TARGET}.tgz
HDF_TGZ2=$LIBRARIES/hdf5-${HDF5_VERSION_2}-${COMPILER_TARGET}.tgz

# Unpack the first hdf5 library
tar xf $HDF_TGZ1
touch hdf5_v1_marker

# Get h5py source tree
gh-clone h5py/h5py
cd h5py

# Compile wheels
UNFIXED_WHEELS=$PWD/unfixed
rm_mkdir $UNFIXED_WHEELS
for H5PY in ${H5PY_VERSIONS}; do
    git checkout "$H5PY"
    # If we have >=2.4 switch to more recent hdf5
    if [ $(lex_ver $H5PY) -ge $(lex_ver 2.4.0) ] && [ -f /hdf5_v1_marker ]; then
        echo "Replacing HDF5 library"
        ( cd .. && rm_archive $HDF_TGZ1 && rm hdf5_v1_marker \
            && tar zxf $HDF_TGZ2 )
    fi
    for PYTHON in ${PYTHON_VERSIONS}; do
        PIP="$(cpython_path $PYTHON $UNICODE_WIDTH)/bin/pip"
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        $PIP install "numpy==$np_ver" "cython==$CYTHON_VERSION"
        echo "Building h5py $H5PY for Python $PYTHON"
        git clean -fxd
        git reset --hard
        $PIP wheel --no-deps -w $UNFIXED_WHEELS .
        # Bundle external shared libraries into the wheels
        # Do this while we still have the matching hdf5 libraries
        for whl in $UNFIXED_WHEELS/h5py-*.whl; do
            auditwheel repair $whl -w $WHEELHOUSE/
            rm -f $whl
        done
    done
done
