#!/bin/bash
# Build h5py wheels
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_h5pies.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_h5pies.sh
# or maybe:
#    docker run --rm -e H5PY_VERSIONS=1.10.4 -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manlinux1_x86_64 /io/build_h5pies.sh
set -e
if [ -z $PYTHON_VERSIONS ]; then
    PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
fi
if [ -z $H5PY_VERSIONS ]; then
    H5PY_VERSIONS="2.2.0 2.2.1 2.3.0 2.3.1 2.4.0 2.5.0 2.6.0"
fi

CYTHON_VERSION=0.22.1
HDF5_VERSION_1=1.8.3
HDF5_VERSION_2=1.8.16

MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

function rm_archive {
    # Remove files listed in archive contents
    tar tzf $1 | grep -v "/$" | xargs rm
}

# Get hdf5 libraries
curl -LO $MANYLINUX_URL/hdf5-${HDF5_VERSION_1}.tgz
curl -LO $MANYLINUX_URL/hdf5-${HDF5_VERSION_2}.tgz

# Unpack the earlier
tar xf hdf5-${HDF5_VERSION_1}.tgz
touch hdf5_v1

# Get h5py source tree
git clone https://github.com/h5py/h5py.git
cd h5py

# Compile wheels
TMP_WHEELS=/tmp
UNFIXED_WHEELS=/io/unfixed
rm -f $UNFIXED_WHEELS/*
for H5PY in ${H5PY_VERSIONS}; do
    git checkout "$H5PY"
    # If we have >=2.4 switch to more recent hdf5
    if [ $(lex_ver $H5PY) -ge $(lex_ver 2.4.0) ] && [ -f /hdf5_v1 ]; then
        echo "Replacing HDF5 library"
        ( cd .. && rm_archive hdf5-${HDF5_VERSION_1}.tgz && rm hdf5_v1 \
            && tar zxf hdf5-${HDF5_VERSION_2}.tgz )
    fi
    for PYTHON in ${PYTHON_VERSIONS}; do
        PIP=/opt/${PYTHON}/bin/pip
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] ; then
            np_ver=1.9.0
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ; then
            np_ver=1.7.0
        else
            np_ver=1.6.1
        fi
        # Put numpy, cython version into the wheelhouse to avoid rebuilding
        $PIP wheel -f $MANYLINUX_URL -w $TMP_WHEELS "numpy==$np_ver" "cython==$CYTHON_VERSION"
        $PIP install -f $TMP_WHEELS "numpy==$np_ver" "cython==$CYTHON_VERSION"
        echo "Building h5py $H5PY for Python $PYTHON"
        git clean -fxd
        git reset --hard
        # Add numpy / cython to requirements to avoid upgrading numpy version
        $PIP wheel -f $TMP_WHEELS -w $UNFIXED_WHEELS "numpy==$np_ver" "cython==$CYTHON_VERSION" .
        # Bundle external shared libraries into the wheels
        # Do this while we still have the matching hdf5 libraries
        for whl in $UNFIXED_WHEELS/h5py-*.whl; do
            auditwheel repair $whl -w /io/wheelhouse/
            rm -f $whl
        done
    done
done
