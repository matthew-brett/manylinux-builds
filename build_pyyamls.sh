#!/bin/bash
set -e

# Manylinux, openblas version, lex_ver
source /io/common_vars.sh

if [ -z "$PYYAML_VERSIONS" ]; then
    PYYAML_VERSIONS="3.11"
fi

# Build yaml library
source /io/library_builders.sh
build_libyaml

# Directory to store wheels
rm_mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP="$(cpython_path $PYTHON)/bin/pip"
    for PYYAML in ${PYYAML_VERSIONS}; do
        echo "Building pyyaml $PYYAML for Python $PYTHON"
        $PIP wheel --no-deps -w unfixed_wheels "pyyaml==$PYYAML"
    done
done

# Bundle external shared libraries into the wheels
repair_wheelhouse unfixed_wheels $WHEELHOUSE
