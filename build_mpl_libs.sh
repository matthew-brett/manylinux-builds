# Build libraries for matplotlib
source /io/library_builders.sh
build_jpeg
build_libpng
build_bzip2
build_freetype
# How do we deal with tcl/tk?
# yum install -y tk-devel
