#!/bin/sh -e
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLite.Interop.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

SHA256=bb599fa265088abb8a7d4af6218cae97df8b9c8ed6f04fb940a5d564920ee6a1
VERSION=1.0.118.0

ZIPNAME="sqlite-netFx-source-$VERSION.zip"

cleanup()
{
	rm -rf src pkg "$ZIPNAME"
}

trap cleanup 0

rm -rf *.zip

cleanup

curl --silent --fail --output "$ZIPNAME" --location "https://system.data.sqlite.org/blobs/$VERSION/$ZIPNAME"

sha256sum "$ZIPNAME" | grep "^$SHA256"

mkdir src

(
	set -e
	cd src
	unzip -q "../$ZIPNAME"
	cd Setup
	chmod +x compile-interop-assembly-release.sh
	./compile-interop-assembly-release.sh
)

DLLNAME=SQLite.Interop
DLLPATH="src/bin/2013/Release/bin/$DLLNAME.dll"

chmod -x "$DLLPATH"

patchelf --remove-rpath "$DLLPATH"

objdump -p "$DLLPATH" | grep NEEDED

strip "$DLLPATH"

ls -ld $(dirname "$DLLPATH")/*

FORMAT=$( objdump -p "$DLLPATH" | grep "$DLLNAME.dll" | while read A; do for B in $A; do C="$B"; done ; echo "$C"; break; done )

case "$FORMAT" in
	*arm )
		ARCH=arm
		;;
	*aarch64 )
		ARCH=arm64
		;;
	*x86-64 )
		ARCH=x64
		;;
	*i386 )
		ARCH=x86
		;;
	* )
		echo FORMAT="$FORMAT" 1>&2
		false
		;;
esac

ID="linux-bionic"

RUNTIME="runtimes/$ID-$ARCH/native"

mkdir -p "pkg/$RUNTIME"

mv "$DLLPATH" "pkg/$RUNTIME/"

(
	set -e

	cd pkg

	zip "../$DLLNAME-$VERSION-$ID.zip" "$RUNTIME/$DLLNAME.dll"
)
