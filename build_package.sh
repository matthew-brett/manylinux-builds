#!/bin/bash
# Depends on:
#   UTIL_DIR
#   REPO_DIR
#   PYTHON_VERSION
#   BUILD_COMMIT
#   UNICODE_WIDTHS  (can be empty)
#   BUILD_DEPENDS  (can be empty)
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/$UTIL_DIR/common_vars.sh

# Unicode widths
def_widths=$(default_unicode_widths $PYTHON_VERSION)
UNICODE_WIDTHS=${UNICODE_WIDTHS:-$def_widths}

# Do any building prior to package building
if [ -n "$BUILD_PRE_SCRIPT" ]; then
    # Library building tools
    source /io/$UTIL_DIR/library_builders.sh
    # Pre-package build script
    source $BUILD_PRE_SCRIPT
fi

# Directory to store wheels
rm_mkdir /unfixed_wheels

# Enter source tree
cd /io/$REPO_DIR

WHEELHOUSE=/io/wheelhouse

# Compile wheels
for UNICODE_WIDTH in ${UNICODE_WIDTHS}; do
    PIP="$(cpython_path $PYTHON_VERSION $UNICODE_WIDTH)/bin/pip"
    if [ -n $BUILD_DEPENDS ]; then
        $PIP install -f $MANYLINUX_URL $BUILD_DEPENDS
    fi
    git checkout $BUILD_COMMIT
    git clean -fxd
    git reset --hard
    $PIP wheel -w /unfixed_wheels --no-deps .
done

# Bundle external shared libraries into the wheels
repair_wheelhouse /unfixed_wheels $WHEELHOUSE
