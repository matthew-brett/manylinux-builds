#!/usr/bin/env sh
# ATLAS RPM build script
#
# Builds unoptimized BLAS / LAPACK RPMs and optimized ATLAS RPM
#
# It would likely be unwise to build this on any-old-machine.  The ATLAS build
# is very long (many hours), because it is tuning itself against the local CPU,
# memory and cache.  In order for this tuning to work, it needs to be the only
# task loading the CPU, and all CPU throttling needs to be turned off.
# Otherwise ATLAS will get the wrong timings and you'll get a build that may
# have bad performance on most CPUs.
#
# Run with:
#  docker run -ti --rm -v $PWD:/io quay.io/pypa/manylinux1_x86_64 /io/build_atlas_rpm.sh
IO_DIR=/io
RPM_OUT_DIR=$IO_DIR/built_rpms
RPM_BUILD=~/rpmbuild
RPM_URL=https://kojipkgs.fedoraproject.org/packages
curl -LO $RPM_URL/lapack/3.5.0/12.fc24/src/lapack-3.5.0-12.fc24.src.rpm
curl -LO $RPM_URL/atlas/3.10.2/12.fc24/src/atlas-3.10.2-12.fc24.src.rpm
# See https://wiki.centos.org/HowTos/RebuildSRPM
yum install -y rpm-build
rpmbuild --version
yum install -y redhat-rpm-config
mkdir -p $RPM_BUILD/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
rpm -i --nomd5 lapack-3.5.0-12.fc24.src.rpm
rpm -i --nomd5 atlas-3.10.2-12.fc24.src.rpm
cd $RPM_BUILD/SPECS
patch < $IO_DIR/lapack.spec.patch
patch < $IO_DIR/atlas.spec.patch
rpmbuild -ba lapack.spec
rpm -Uvh ../RPMS/x86_64/*
# This will be very very long
rpmbuild -ba atlas.spec
# Copy out built packages
mkdir -p $RPM_OUT_DIR
cp -r $RPM_BUILD/RPMS/* $RPM_OUT_DIR
