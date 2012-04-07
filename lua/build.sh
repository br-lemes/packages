#!/bin/sh

# http://www.lua.org/ 
PACKAGE=lua
VERSION51=5.1.5
VERSION52=5.2.0

MD5SUM51=2e115fe26e435e33b0d5c022e4490567
MD5SUM52=f1ea831f397214bae8a265995ab1a93e

PKGPATH51=$PACKAGE-$VERSION51
PKGPATH52=$PACKAGE-$VERSION52
DOWNLOAD51=$PKGPATH51.tar.gz
DOWNLOAD52=$PKGPATH52.tar.gz
PKGVERSION=1

usage() {
cat << EOF
Usage: $(basename $0) package[51|52] | install[51|52] | uninstall[51|52] | clean
       $(basename $0) [-h | -v]

       package       Download, build and package $PACKAGE 5.1 and/or 5.2
       install       Install $PACKAGE 5.1 and/or 5.2 binaries and include files
       uninstall     Remove $PACKAGE 5.1 and/or 5.2 binaries and include files
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

get51() {
  if [ ! -e $DOWNLOAD51 ]; then
    wget http://www.lua.org/ftp/$DOWNLOAD51
    [ $? != 0 ] && exit 1
  else
    echo "$MD5SUM51  $DOWNLOAD51" | md5sum -c
    if [ $? != 0 ]; then
      rm $DOWNLOAD51
      get51
    fi
  fi
}

build51() {
  tar xzf $DOWNLOAD51
  cd $PKGPATH51/src
  make all MYCFLAGS="-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s &&
  make liblua5.1.so LUA_A=liblua5.1.so "AR=gcc -Wl,-E -shared -o" "RANLIB=strip --strip-unneeded"
  [ $? != 0 ] && exit 1
  cd ../..
}

v51() {
  get51
  build51
  mkdir -p package/usr/bin package/usr/lib package/var/lib/lrpkg \
  package/usr/local/share/lua/5.1 package/usr/local/lib/lua/5.1
  cp $PKGPATH51/src/lua package/usr/bin/lua5.1
  cp $PKGPATH51/src/liblua5.1.so package/usr/lib
  ln -s lua5.1 package/usr/bin/lua
  ln -s liblua5.1.so package/usr/lib/liblua.so
  touch package/var/lib/lrpkg/lua5.1.list
  cat << EOF > package/var/lib/lrpkg/lua5.1.version
VERSION=$VERSION51-$PKGVERSION
BUILD=$(date +%F-%Z)
EOF
  find package -type f | sed s/package//  > package/var/lib/lrpkg/lua5.1.list
  find package -type l | sed s/package// >> package/var/lib/lrpkg/lua5.1.list
  find package -type d -empty | sed s/package// >> package/var/lib/lrpkg/lua5.1.list
  cd package
  tar czf ../lua5.1.tgz *
  cd ..
  rm -rf package
}

get52() {
  if [ ! -e $DOWNLOAD52 ]; then
    wget http://www.lua.org/ftp/$DOWNLOAD52
    [ $? != 0 ] && exit 1
  else
    echo "$MD5SUM52  $DOWNLOAD52" | md5sum -c
    if [ $? != 0 ]; then
      rm $DOWNLOAD52
      get52
    fi
  fi
}

build52() {
  tar xzf $DOWNLOAD52
  cd $PKGPATH52/src
  make all MYCFLAGS="-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s &&
  make liblua52.so LUA_A=liblua52.so "AR=gcc -Wl,-E -shared -o" "RANLIB=strip --strip-unneeded"
  [ $? != 0 ] && exit 1
  cd ../..
}

v52() {
  get52
  build52
  mkdir -p package/usr/bin package/usr/lib package/var/lib/lrpkg \
  package/usr/local/share/lua/5.2 package/usr/local/lib/lua/5.2
  cp $PKGPATH52/src/lua package/usr/bin/lua52
  cp $PKGPATH52/src/liblua52.so package/usr/lib
  ln -s lua52 package/usr/bin/lua
  ln -s liblua52.so package/usr/lib/liblua.so
  touch package/var/lib/lrpkg/lua5.2.list
  cat << EOF > package/var/lib/lrpkg/lua5.2.version
VERSION=$VERSION52-$PKGVERSION
BUILD=$(date +%F-%Z)
EOF
  find package -type f | sed s/package//  > package/var/lib/lrpkg/lua5.2.list
  find package -type l | sed s/package// >> package/var/lib/lrpkg/lua5.2.list
  find package -type d -empty | sed s/package// >> package/var/lib/lrpkg/lua5.2.list
  cd package
  tar czf ../lua5.2.tgz *
  cd ..
  rm -rf package
}

install51() {
  get51
  build51
  cd $PKGPATH51/src
  cp lua /usr/bin/lua5.1
  cp luac /usr/bin/luac5.1
  cp liblua.a /usr/lib/liblua5.1.a
  cp liblua5.1.so /usr/lib
  mkdir /usr/include/lua5.1
  cp lualib.h luaconf.h ../etc/lua.hpp lua.h lauxlib.h /usr/include/lua5.1
  cd ../..
}

install52() {
  get52
  build52
  cd $PKGPATH52/src
  cp lua /usr/bin/lua52
  cp luac /usr/bin/luac52
  cp liblua.a /usr/lib/liblua52.a
  cp liblua52.so /usr/lib
  mkdir /usr/include/lua5.2
  cp lualib.h luaconf.h lua.hpp lua.h lauxlib.h /usr/include/lua5.2
  cd ../..
}

uninstall51() {
  rm /usr/bin/lua5.1 /usr/bin/luac5.1 /usr/lib/liblua5.1.a /usr/lib/liblua5.1.so
  rm -rf /usr/include/lua5.1
}

uninstall52() {
  rm /usr/bin/lua52 /usr/bin/luac52 /usr/lib/liblua52.a /usr/lib/liblua52.so
  rm -rf /usr/include/lua5.2
}

clean() {
  rm -rf $PKGPATH51 $PKGPATH52 lua5.1.tgz lua5.2.tgz
}

if [ $# != 1 ]; then usage; exit 0; fi

case $1 in
  package51) v51;;
  package52) v52;;
  package) v51; v52;;
  install51) install51;;
  install52) install52;;
  install) install51; install52;;
  uninstall51) uninstall51;;
  uninstall52) uninstall52;;
  uninstall) uninstall51; uninstall52;;
  clean) clean;;
  -v) version;;
# -h) usage;;
   *) usage;;
esac
