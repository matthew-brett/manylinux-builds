# Build libraries for matplotlib
curl -LO http://zlib.net/zlib-1.2.8.tar.gz
tar zxvf zlib-1.2.8.tar.gz
cd zlib-1.2.8
./configure
make && make install
cd ..
curl -LO http://ijg.org/files/jpegsrc.v9b.tar.gz
tar zxvf jpegsrc.v9b.tar.gz
cd jpeg-9b/
./configure
make && make install
cd ..
curl -LO http://download.sourceforge.net/libpng/libpng-1.6.21.tar.gz
tar zxvf libpng-1.6.21.tar.gz
cd libpng-1.6.21
./configure
make && make install
cd ..
curl -LO http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
tar zxvf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make -f Makefile-libbz2_so
make install
cd ..
curl -LO http://download.savannah.gnu.org/releases/freetype/freetype-2.6.3.tar.gz
tar zxvf freetype-2.6.3.tar.gz
cd freetype-2.6.3
./configure
make && make install
cd ..
