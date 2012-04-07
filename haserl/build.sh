#!/bin/sh

# http://haserl.sourceforge.net/
PACKAGE=haserl
VERSION=0.9.29

MD5SUM=4cac9409530200b4a7a82a48ec174800

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
    wget http://sourceforge.net/projects/haserl/files/haserl-devel/$DOWNLOAD/download -O $DOWNLOAD
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
    if [ ! -f /usr/include/lua.h -a -d /usr/include/lua5.1 ]; then
      pkg-config --version > /dev/null
      if [ $? != 0 ]; then # lie to configure
        sed -i 's|pkg-config --exists lua5.1|true|' configure
        sed -i 's|`pkg-config .LUALIB --cflags`|-I/usr/include/lua5.1|' configure
      fi
    fi
    ./configure --with-lua
  fi
  make
  [ $? != 0 ] && exit 1
  cd ..
}

package() {
  get
  build
  mkdir -p package/usr/bin package/var/lib/lrpkg
  strip $PKGPATH/src/haserl
  cp $PKGPATH/src/haserl package/usr/bin
  touch package/var/lib/lrpkg/$PACKAGE.list
  cat << EOF > package/var/lib/lrpkg/$PACKAGE.version
VERSION=$VERSION-$PKGVERSION
BUILD=$(date +%F-%Z)
EOF
  find package -type f | sed s/package// > package/var/lib/lrpkg/$PACKAGE.list
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
