#!/bin/bash
# Build libh5py libraries
# Run with:
#    docker run --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_hdf5s.sh
# Followed by something like:
#    scp libraries/hdf5-1.8.3.tgz nipy.bic.berkeley.edu:/home/manylinux
#    scp libraries/hdf5-1.8.16.tgz nipy.bic.berkeley.edu:/home/manylinux
set -e

# Manylinux, openblas version, lex_ver, Python versions
source /io/common_vars.sh

if [ -z "$HDF5_VERSIONS" ]; then
    HDF5_VERSIONS="1.8.3"
fi

SZIP_VERSION=2.1
SZIP_URL=http://www.hdfgroup.org/ftp/lib-external/szip/
HDF5_URL=http://www.hdfgroup.org/ftp/HDF5/releases

yum install -y zlib-devel

for HDF5_VERSION in ${HDF5_VERSIONS}; do
    curl -sLO $SZIP_URL/$SZIP_VERSION/src/szip-$SZIP_VERSION.tar.gz
    tar zxf szip-$SZIP_VERSION.tar.gz
    ( cd szip-$SZIP_VERSION && ./configure --enable-encoding=no --prefix=/usr/local && make && make install > /dev/null )
    curl -sLO $HDF5_URL/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz
    tar zxf hdf5-$HDF5_VERSION.tar.gz
    ( cd hdf5-$HDF5_VERSION && ./configure --prefix=/usr/local --with-szlib=/usr/local && make && make install )
    tar zcf /io/libraries/hdf5-$HDF5_VERSION.tgz /usr/local/lib/* /usr/local/bin/*h5* /usr/local/include/* /usr/local/hdf5*
    rm -rf /usr/local/lib/* /usr/local/bin/*h5* /usr/local/include/* /usr/local/hdf5*
done
