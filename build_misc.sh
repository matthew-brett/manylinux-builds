#!/bin/bash
set -e
PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

# Add manylinux repo
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
find-links = $MANYLINUX_URL
EOF

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP=/opt/$PYTHON/bin/pip
    # To satisfy packages depending on numpy distuils in setup.py
    $PIP install numpy
    echo "Building for $PYTHON"
    while read req_line; do
        echo "Building $req_line"
        echo $req_line > requirements.txt
        $PIP wheel -w ../unfixed_wheels -r requirements.txt
    done < /io/misc_requirements.txt
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
