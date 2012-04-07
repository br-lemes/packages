#!/bin/sh

# http://www.darwinsys.com/file/
PACKAGE=file
VERSION=5.11

MD5SUM=16a407bd66d6c7a832f3a5c0d609c27b

PKGPATH=$PACKAGE-$VERSION
DOWNLOAD=$PKGPATH.tar.gz
PKGVERSION=1

usage() {
cat <<EOF
Usage: $(basename $0) package | clean
       $(basename $0) [-h | -v]

       package       Download, build and package $PACKAGE
       clean         Remove build files
       -h            Show this help
       -v            Show version

breno@br-lemes.net
http://www.br-lemes.net/
EOF
}

version() {
  echo "$PACKAGE package build script version $PKGVERSION"
}

get() {
  if [ ! -f $DOWNLOAD ]; then
    wget ftp://ftp.astron.com/pub/file/$DOWNLOAD
    [ $? != 0 ] && exit 1
  else
    echo "$MD5SUM  $DOWNLOAD" | md5sum -c
    if [ $? != 0 ]; then
      rm $DOWNLOAD
      get
    fi
  fi
}

build() {
  tar xzf $DOWNLOAD
  cd $PKGPATH
  if [ ! -f Makefile ]; then
    sed -i s/-Wextra// configure*
    ./configure --prefix=/usr
  fi
  make
  [ $? != 0 ] && exit 1
  cd ..
}

package() {
  get
  build
  make -C $PKGPATH install prefix=$(pwd)/package/usr
  mkdir -p package/var/lib/lrpkg
  touch package/var/lib/lrpkg/$PACKAGE.list
  cat << EOF > package/var/lib/lrpkg/$PACKAGE.version
VERSION=$VERSION-$PKGVERSION
BUILD=$(date +%F-%Z)
EOF
  rm -rf package/usr/include package/usr/lib/*a package/usr/share/man
  find package -type f | sed s/package//  > package/var/lib/lrpkg/$PACKAGE.list
  find package -type l | sed s/package// >> package/var/lib/lrpkg/$PACKAGE.list
  cd package
  tar czf ../$PACKAGE.tgz *
  cd ..
  rm -rf package
}

clean() {
  rm -rf $PKGPATH $PACKAGE.tgz
}

if [ $# != 1 ]; then usage; exit 0; fi

case $1 in
  package) package;;
  clean) clean;;
  -v) version;;
# -h) usage;;
   *) usage;;
esac
