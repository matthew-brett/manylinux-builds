#!/bin/bash
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_stack.sh
# or something like:
#    docker run --rm -e PYTHON_VERSIONS=2.7 -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_stack.sh
export BLAS_SOURCE="openblas"
export NUMPY_VERSIONS=1.10.4
export SCIPY_VERSIONS=0.17.0
export SCIKIT_LEARN_VERSIONS=0.17.1
export PANDAS_VERSIONS=0.18.0
bash /io/build_openblas.sh
bash /io/build_numpies.sh
bash /io/build_scipies.sh
bash /io/build_sklearns.sh
bash /io/build_pandas.sh
echo "Done"
