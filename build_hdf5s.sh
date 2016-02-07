#!/bin/bash
# Build libh5py library
set -e

SZIP_VERSION=2.1
SZIP_URL=http://www.hdfgroup.org/ftp/lib-external/szip/
HDF5_VERSIONS="1.8.3 1.8.18"
HDF5_URL=http://www.hdfgroup.org/ftp/HDF5/releases

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

yum install -y zlib-devel

for HDF5_VERSION in ${HDF5_VERSIONS}; do
    curl -sLO $SZIP_URL/$SZIP_VERSION/src/szip-$SZIP_VERSION.tar.gz
    tar zxf szip-$SZIP_VERSION.tar.gz
    ( cd szip-$SZIP_VERSION && ./configure --enable-encoding=no --prefix=/usr/local && make && make install )
    curl -sLO $HDF5_URL/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz
    tar zxf hdf5-$HDF5_VERSION.tar.gz
    ( cd hdf5-$HDF5_VERSION && ./configure --prefix=/usr/local --with-szlib=/usr/local && make && make install )
    tar zcf /io/hdf5-$HDF5_VERSION.tgz /usr/local/lib/* /usr/local/bin/*h5* /usr/local/include/* /usr/local/hdf5*
    rm -rf /usr/local/lib/* /usr/local/bin/*h5* /usr/local/include/* /usr/local/hdf5*
done
