#!/bin/bash
set -e
PYTHON_VERSIONS="2.6 2.7 3.3 3.4 3.5"
SCIPY_VERSIONS="0.9.0 0.10.0 0.10.1 0.11.0 0.12.0 0.12.1 \
    0.13.0 0.13.1 0.13.2 0.13.3 0.14.0 0.14.1\
    0.15.0 0.15.1 0.16.0 0.16.1 0.17.0"
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

# Install openblas
curl -LO $MANYLINUX_URL/openblas_0.2.15.tgz
tar xf openblas_0.2.15.tgz

# Directory to store wheels
mkdir unfixed_wheels

# Compile wheels
for PYTHON in ${PYTHON_VERSIONS}; do
    PIP=/opt/$PYTHON/bin/pip
    PIPI_ML="$PIP install -f $MANYLINUX_URL"
    if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ]; then
        $PIPI_ML "numpy==1.9.0"
    elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] ||
        [ $(lex_ver $SCIPY) -ge $(lex_ver 0.17) ] ; then
        $PIPI_ML "numpy==1.7.0"
    else
        $PIPI_ML "numpy==1.6.0"
    fi
    for SCIPY in ${SCIPY_VERSIONS}; do
        # Does Python 3.5 need scipy >= 0.16?
        if [ $(lex_ver $PYTHON) -ge $(lex_ver 3.5) ] &&
            [ $(lex_ver $SCIPY) -lt $(lex_ver 0.16) ] ; then
            continue
        elif [ $(lex_ver $PYTHON) -ge $(lex_ver 3) ] &&
            [ $(lex_ver $SCIPY) -lt $(lex_ver 0.12) ] ; then
            continue
        fi
        echo "Building scipy $SCIPY for Python $PYTHON"
        $PIP wheel -w ../unfixed_wheels "scipy==$SCIPY"
    done
done

# Bundle external shared libraries into the wheels
for whl in unfixed_wheels/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done
