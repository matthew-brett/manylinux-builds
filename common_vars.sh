# Useful defines common across builds
IO_PATH="${IO_PATH:-/io}"
# BLAS_SOURCE can be "atlas" or "openblas"
BLAS_SOURCE="${BLAS_SOURCE:-openblas}"
PYTHON_VERSIONS="${PYTHON_VERSIONS:-2.6 2.7 3.3 3.4 3.5}"
OPENBLAS_VERSION="${OPENBLAS_VERSION:-0.2.18}"
# ATLAS_TYPE can be 'default' or 'custom'
ATLAS_TYPE="${ATLAS_TYPE:-default}"
# BUILD_SUFFIX appends a string to output library and wheel path
BUILD_SUFFIX="${BUILD_SUFFIX:-}"
# Auditwheel commit to update to, if updating
# AUDITWHEEL_COMMIT=3db32a73f9058428fe7192e7a584b4a330fe114b

# Get our own location on this filesystem
MLBUILD_DIR=$(dirname "${BASH_SOURCE[0]}")

# Get common manylinux functions / constants
source $MLBUILD_DIR/multibuild/manylinux_utils.sh

# Probably don't want to change the stuff below this line

# Get extra wheels from Rackspace container
MANYLINUX_URL=https://5cf40426d9f06eb7461d-6fe47d9331aba7cd62fc36c7196769e4.ssl.cf2.rackcdn.com

function compiler_target {
    touch _test.c
    gcc -c _test.c
    local file_test=$(file _test.o)
    rm -f _test.c _test.o
    if [[ $file_test =~ "ELF 32-bit" ]]; then
        echo 'i686'
    elif [[ $file_test =~ "ELF 64-bit" ]]; then
        echo 'x86_64'
    fi
}

COMPILER_TARGET=$(compiler_target)

function build_archive {
    # For back compatibility, please prefer build_simple
    local name_version=$(echo $1 | awk -F "-" '{print $1 " " $2}')
    local url=$2
    source $MY_DIR/multibuild/library_builders.sh
    build_simple $name_version $url
}

function default_unicode_widths {
    local py_ver="${1:-2.7}"
    if [ $(lex_ver "$py_ver") -le $(lex_ver 3) ]; then
        echo "32 16"
    else
        echo "32"
    fi
}

function add_manylinux_repo {
    cat << EOF > /etc/yum.repos.d/manylinux.repo
[manylinux1-x86_64]
name=RPMs for manylinux 64-bit image
baseurl=https://nipy.bic.berkeley.edu/manylinux/rpms
gpgcheck=0
EOF
}

function get_openblas {
    # Install OpenBLAS
    local openblas_version="${1:-$OPENBLAS_VERSION}"
    tar xf $LIBRARIES/openblas_${openblas_version}-${COMPILER_TARGET}.tgz
    # Force scipy to use OpenBLAS regardless of what numpy uses
    cat << EOF > $HOME/site.cfg
[openblas]
library_dirs = /usr/local/lib
include_dirs = /usr/local/include
EOF
}

function get_atlas {
    # Install ATLAS from custom or default repo
    local atlas_type="${1:-$ATLAS_TYPE}"
    if [ "$atlas_type" == "custom" ]; then
        add_manylinux_repo
    fi
    yum install -y atlas-devel
    # Force scipy to use ATLAS regardless of what numpy uses
    cat << EOF > $HOME/site.cfg
[atlas]
library_dirs = /usr/lib64/atlas:/usr/lib/atlas
include_dirs = /usr/include/atlas
EOF
}

function get_blas {
    # Get openblas or atlas
    local blas_source="${1:-$BLAS_SOURCE}"
    if [ "$blas_source" == "atlas" ]; then
        get_atlas
    elif [ "$blas_source" == "openblas" ]; then
        get_openblas
    fi
}

function shebang_for {
    # Return application after shebang line for script
    # Parameters
    #    binary_name
    local bin_path=$(which $1)
    if [ -z "$bin_path" ]; then
        echo "$1 not on path"
        exit 1
    fi
    local bin_shebang=$(head -1 $bin_path)
    echo ${bin_shebang:2}
}

function update_auditwheel {
    # Update auditwheel if necessary
    local aw_commit=${1:-$AUDITWHEEL_COMMIT}
    if [ -z "$aw_commit" ]; then return; fi
    $(cpython_path 3.5)/bin/pip3 install git+https://github.com/pypa/auditwheel@${aw_commit}
    ln -sf $(cpython_path 3.5)/bin/auditwheel /usr/local/bin
}

WHEELHOUSE=$IO_PATH/wheelhouse${BUILD_SUFFIX}
LIBRARIES=$IO_PATH/libraries${BUILD_SUFFIX}

mkdir -p $WHEELHOUSE
mkdir -p $LIBRARIES
update_auditwheel
