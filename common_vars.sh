# Useful defines common across builds
IO_PATH="${IO_PATH:-/io}"
# BLAS_SOURCE can be "atlas" or "openblas"
BLAS_SOURCE="${BLAS_SOURCE:-atlas}"
PYTHON_VERSIONS="${PYTHON_VERSIONS:-2.6 2.7 3.3 3.4 3.5}"
OPENBLAS_VERSION="${OPENBLAS_VERSION:-0.2.16}"

# Probably don't want to change the stuff below this line
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

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
    # * u_suff ("" or "u" default "u")
    local py_ver="${1:-2.7}"
    local u_suff="${2:-u}"
    # For Python >= 3.3, "u" suffix not meaningful
    if [ $(lex_ver $py_ver) -ge $(lex_ver 3.3) ]; then
        u_suff=""
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
    # Install openblas
    tar xf $LIBRARIES/openblas_${OPENBLAS_VERSION}.tgz
}

function get_atlas {
    add_manylinux_repo
    yum install -y atlas-devel
}

function get_blas {
    if [ "$BLAS_SOURCE" == "atlas" ]; then
        get_atlas
    elif [ "$BLAS_SOURCE" == "openblas" ]; then
        get_openblas
    fi
}

function install_auditwheel {
    $(cpython_path 3.5)/bin/pip3 install auditwheel
    ln -s $(cpython_path 3.5)/bin/auditwheel /usr/local/bin
}

WHEELHOUSE=$IO_PATH/wheelhouse
LIBRARIES=$IO_PATH/libraries
mkdir -p $WHEELHOUSE
mkdir -p $LIBRARIES
install_auditwheel
