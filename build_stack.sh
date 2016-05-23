#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_stack.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_stack.sh
export BLAS_SOURCE="${BLAS_SOURCE:-openblas}"
export ATLAS_TYPE="${ATLAS_TYPE:-default}"
export BUILD_SUFFIX="${BUILD_SUFFIX:--$BLAS_SOURCE}"
export CYTHON_VERSIONS="${CYTHON_VERSIONS:-0.23.5}"
export NUMPY_VERSIONS="${NUMPY_VERSIONS:-1.11.0}"
export SCIPY_VERSIONS="${SCIPY_VERSIONS:-0.17.1}"
export SCIKIT_LEARN_VERSIONS="${SCIKIT_LEARN_VERSIONS:-0.17.1}"
export PANDAS_VERSIONS="${PANDAS_VERSIONS:-0.18.0}"
export NUMEXPR_VERSIONS="${NUMEXPR_VERSIONS:-2.5.1}"

if [ "$BLAS_SOURCE" == "openblas" ]; then
    bash /io/build_openblas.sh
fi
bash /io/build_numpies.sh
bash /io/build_scipies.sh
bash /io/build_sklearns.sh
bash /io/build_pandas.sh
bash /io/build_numexprs.sh
