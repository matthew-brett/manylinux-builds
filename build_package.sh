#!/bin/bash
# Depends on:
#   REPO_DIR | PKG_SPEC
#       (REPO_DIR for in source build; PKG_SPEC for pip build)
#   PYTHON_VERSION
#   BUILD_COMMIT
#   UNICODE_WIDTH  (can be empty)
#   BUILD_DEPENDS  (can be empty)
set -e

# Manylinux, openblas version, lex_ver, Python versions
MY_DIR=$(dirname "${BASH_SOURCE[0]}")
source $MY_DIR/common_vars.sh

# Unicode widths
UNICODE_WIDTH=${UNICODE_WIDTH:-32}
WHEEL_SDIR=${WHEEL_SDIR:-wheelhouse}

# Do any building prior to package building
if [ -n "$BUILD_PRE_SCRIPT" ]; then
    # Library building tools
    source $MY_DIR/library_builders.sh
    # Pre-package build script
    source $BUILD_PRE_SCRIPT
fi

# Directory to store wheels
rm_mkdir /unfixed_wheels

if [ -n "$REPO_DIR" ]; then
    # Enter source tree
    cd /io/$REPO_DIR
    build_source="."
elif [ -n "$PKG_SPEC" ]; then
    build_source=$PKG_SPEC
else:
    echo "Must specify REPO_DIR or PKG_SPEC"
    exit 1
fi

WHEELHOUSE=/io/$WHEEL_SDIR

# Compile wheels
for width in ${UNICODE_WIDTH}; do
    PIP="$(cpython_path $PYTHON_VERSION $width)/bin/pip"
    if [ -n "$BUILD_DEPENDS" ]; then
        $PIP install -f $MANYLINUX_URL $BUILD_DEPENDS
    fi
    if [ -n "$REPO_DIR" ]; then
        git checkout $BUILD_COMMIT
        git clean -fxd
        git reset --hard
        git submodule update --init --recursive
    fi
    $PIP wheel -f $MANYLINUX_URL -w /unfixed_wheels --no-deps $build_source
done

# Bundle external shared libraries into the wheels
repair_wheelhouse /unfixed_wheels $WHEELHOUSE
