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
# UNICODE_WIDTH selects "32"=wide (UCS4) or "16"=narrow (UTF-16) builds
UNICODE_WIDTH="${UNICODE_WIDTH:-32}"

# Probably don't want to change the stuff below this line
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

function strip_dots {
    # Strip "." characters from string
    echo $1 | sed "s/\.//g"
}

function build_archive {
    local pkg_root=$1
    local url=$2
    curl -LO $url/${pkg_root}.tar.gz
    tar zxf ${pkg_root}.tar.gz
    (cd $pkg_root && ./configure && make && make install)
    rm -rf $pkg_root
}

function cpython_path {
    # Return path to cpython given
    # * version (of form "2.7")
    # * u_width ("16" or "32" default "32")
    #
    # For back-compatibility "u" as u_width also means "32"
    local py_ver="${1:-2.7}"
    local u_width="${2:-${UNICODE_WIDTH}}"
    local u_suff=u
    # Back-compatibility
    if [ "$u_width" == "u" ]; then u_width=32; fi
    # For Python >= 3.3, "u" suffix not meaningful
    if [ $(lex_ver $py_ver) -ge $(lex_ver 3.3) ] ||
        [ "$u_width" == "16" ]; then
        u_suff=""
    elif [ "$u_width" != "32" ]; then
        echo "Incorrect u_width value $u_width"
        # exit 1
    fi
    local no_dots=$(strip_dots $py_ver)
    echo "/opt/python/cp${no_dots}-cp${no_dots}m${u_suff}"
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
    tar xf $LIBRARIES/openblas_${openblas_version}.tgz
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

function get_freetype {
    yum install -y libpng-devel libjpeg-devel
    curl -LO http://downloads.sourceforge.net/project/freetype/freetype2/2.6.3/freetype-2.6.3.tar.bz2 
    tar xf freetype-*.tar.bz2
    (cd / && patch -p0 -N < /io/pngconf.patch)
    export PNG_SKIP_SETJMP_CHECK=1
    (cd freetype-* && ./configure && make && make install)
}

function gh-clone {
    git clone https://github.com/$1
}

function rm_mkdir {
    # Remove directory if present, then make directory
    local path=$1
    if [ -d "$path" ]; then
        rm -rf $path
    fi
    mkdir $path
}

function repair_wheelhouse {
    local in_dir=$1
    local out_dir=$2
    for whl in $in_dir/*.whl; do
        if [[ $whl == *none-any.whl ]]; then
            cp $whl $out_dir
        else
            auditwheel repair $whl -w $out_dir/
        fi
    done
    chmod -R a+rwX $out_dir
}

WHEELHOUSE=$IO_PATH/wheelhouse${BUILD_SUFFIX}
LIBRARIES=$IO_PATH/libraries${BUILD_SUFFIX}

mkdir -p $WHEELHOUSE
mkdir -p $LIBRARIES
