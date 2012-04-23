#!/bin/sh
#
# Compila diversos pacotes no formato de addon do SmartRouter PROJECT
# Geralmente também é compatível com BrazilFW 2.x e Router Firewall System
#
# Copyright (c) 2012 Breno Ramalho Lemes <breno@br-lemes.net>
# http://www.br-lemes.net/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Qualquer erro, cai fora. Verifique manualmente os erros, é uma ferramneta
# de desenvolvimento, não de usuário final.
set -e 

# É a primeira versão, mas não quero confundir com o build script antigo
BUILD_VERSION="3" 

BUILD_TARGETS=$(echo build/* | sed 's,build/,,g')

for i in $BUILD_TARGETS; do
  . build/$i
done

usage() {
cat <<EOF
Usage:	$(basename $0) COMMAND [PACKAGE]
	$(basename $0) [-h | -v]

Commands:
	package		Download, build and package
	install		Install package binaries and include files
	uninstall	Remove package binaries and include files
	clean		Remove build files

Packages:
EOF
for i in $BUILD_TARGETS; do
	eval echo \"\$${i}_desc\"
done
cat <<EOF
	all		Run the command in all available packages (default)

Options:
	-h		Show this help
	-v		Show version

breno@br-lemes.net
http://www.br-lemes.net/
EOF
exit 0
}

version() {
	echo "Build script version $BUILD_VERSION"
	echo "Packages: $BUILD_TARGETS"
	exit 0
}

# Parâmetros: $1=url $2=arquivo $3=md5sum, sendo "$1$2" a url completa
download() {
	# Se o arquivo não existir, baixa ele
	if [ ! -f "$2" ]; then 
		if ! wget "$1$2"; then exit 1; fi
	fi
	# Se o md5sum não bater, remove e baixa novamente
	if ! echo "$3  $2" | md5sum -c; then
		rm "$2"
		download "$1" "$2" "$3"
	fi
}

# Parâmetros: $1=package
package() {
	[ ! -d "$1" ] && mkdir "$1"
	cd "$1"
	mkdir -p package/var/lib/lrpkg
	local func="${1}_download"; $func
	func="${1}_build";$func
	func="${1}_package";$func
	func="${1}_version";$func
	touch "package/var/lib/lrpkg/$1.list"
	find package -type d -empty | sed 's,package/,,' > "package/var/lib/lrpkg/$1.list"
	find package -type f | sed 's,package/,,' >> "package/var/lib/lrpkg/$1.list"
	find package -type l | sed 's,package/,,' >> "package/var/lib/lrpkg/$1.list"
	cd package
	tar czf "../$1.tgz" *
	cd ..
	rm -rf package
	cd ..
}

# Parâmetros: $1=package
clean() {
	[ ! -d "$1" ] && mkdir "$1"
	cd "$1"
	local func="${1}_clean"; $func
	cd ..
}

install() {
	# Alguns pacotes podem não ter o comando install e isso é perfeitamente normal
	local func="${1}_install"
	if type $func > /dev/null 2>&1; then
		[ ! -d "$1" ] && mkdir "$1"
		cd "$1"
		func="${1}_download"; $func
		func="${1}_build";$func
		func="${1}_install";$func
		cd ..
	fi
}

uninstall() {
	# Alguns pacotes podem não ter o comando install e isso é perfeitamente normal
	local func="${1}_uninstall"
	if type $func > /dev/null 2>&1; then
		[ ! -d "$1" ] && mkdir "$1"
		cd "$1"
		func="${1}_uninstall"; $func
		cd ..
	fi
}

local command build_pkg found_pkg
case "$1" in
	package|install|uninstall|clean) command="$1";;
	-h) usage;;
	-v) version;;
	*) echo "Invalid command: $1" >&2; exit 1;;
esac
found_pkg=0
for i in $BUILD_TARGETS; do
	if [ "$2" = "" -o "$2" = "all" -o "$2" = "$i" ]; then
		found_pkg=1
		$command "$i"
	fi
done
if test "$found_pkg" = 0; then
	echo "Invalid package: $2" >&2
	exit 1
fi
