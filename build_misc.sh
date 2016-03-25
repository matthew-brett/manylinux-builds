#!/bin/bash
# Build a miscellaneous collection of wheels
# These wheels do not depend on numpy or any external library.
# Wheels to build listed in "misc_requirements.txt"
#
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_misc.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_misc.sh
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

# Add manylinux and local repo to pip config
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
find-links = $WHEELHOUSE
find-links = $MANYLINUX_URL
EOF

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    # To satisfy packages depending on numpy distutils in
    # setup.py
    $PIP install numpy
    echo "Building for $PYTHON"
    while read req_line; do
        echo "Building $req_line"
        echo $req_line > requirements.txt
        $PIP wheel -w ../unfixed_wheels -r requirements.txt
    done < /io/misc_requirements.txt
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
