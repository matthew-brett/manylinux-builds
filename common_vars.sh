# Useful defines common across builds

if [ -z "$PYTHON_VERSIONS" ]; then
    PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
fi

OPENBLAS_VERSION=0.2.16.rc1
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

function build_archive {
    local pkg_root=$1
    local url=$2
    curl -LO $url/${pkg_root}.tar.gz
    tar zxf ${pkg_root}.tar.gz
    (cd $pkg_root && ./configure && make && make install)
    rm -rf $pkg_root
}

WHEELHOUSE=/io/wheelhouse
LIBRARIES=/io/libraries
mkdir -p $WHEELHOUSE
mkdir -p $LIBRARIES
