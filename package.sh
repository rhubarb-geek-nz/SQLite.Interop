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

SHA256=ed1320e92860ef47d0adb0241a662bcc5387bb1b866f3baf323ee95849dd84c4
VERSION=1.0.116.0

ZIPNAME="sqlite-netFx-source-$VERSION.zip"

cleanup()
{
	rm -rf src pkg "$ZIPNAME"
}

trap cleanup 0

rm -rf *.zip

cleanup

curl --silent --fail --output "$ZIPNAME" --location "https://system.data.sqlite.org/blobs/$VERSION/$ZIPNAME"

case $(uname) in
	Darwin )
		shasum -a 256 "$ZIPNAME" | grep "^$SHA256"
		;;
	* )
		sha256sum "$ZIPNAME" | grep "^$SHA256"
		;;
esac

mkdir src

(
	set -e
	cd src
	unzip -q "../$ZIPNAME"
	cd Setup
	case $(uname) in
		Darwin )
			if grep "arch arm64" compile-interop-assembly-release.sh
			then
				:
			else
				sed "s/-arch x86_64/-arch x86_64 -arch arm64/g" < compile-interop-assembly-release.sh > compile-interop-assembly-osx.sh 
				mv compile-interop-assembly-osx.sh compile-interop-assembly-release.sh 
			fi
			;;
		* )
			;;
	esac
	chmod +x compile-interop-assembly-release.sh
	./compile-interop-assembly-release.sh
)

DLLNAME=SQLite.Interop
DLLPATH="src/bin/2013/Release/bin/$DLLNAME.dll"

ls -ld $(dirname "$DLLPATH")/*

if strip "$DLLPATH" 2>/dev/null
then
	ls -ld "$DLLPATH"
fi

case $(uname) in
	Darwin )
		ID="osx"
		if test -z "$MACOSX_DEPLOYMENT_TARGET"
		then
			VERSION_ID=$(sw_vers -productVersion)
		else
			VERSION_ID="$MACOSX_DEPLOYMENT_TARGET"
		fi
		ARCH=
		;;
	Linux )
		FORMAT=$( objdump -p "$DLLPATH" | grep "$DLLNAME.dll" | while read A; do for B in $A; do C="$B"; done ; echo "$C"; break; done ) 

		ID=$( . /etc/os-release ; echo $ID )
		VERSION_ID=$( . /etc/os-release ; echo $VERSION_ID )

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

		case "$VERSION_ID" in
			*.*.* | *.*.*.* )
				VERSION_ID=$(echo $VERSION_ID | sed "y/./ /" | while read A B C; do echo $A.$B; done )
				;;
			* )
				;;
		esac

		for d in $( . /etc/os-release ; echo $ID $ID_LIKE )
		do
			case "$d" in
				rhel | fedora | mariner | opensuse* )
					VERSION_ID=$(echo $VERSION_ID | sed "y/./ /" | while read A B; do echo $A; done )
					;;
				* )
					;;
			esac
		done

		case "$ID" in
			opensuse-* )
				ID=opensuse
				;;
			* )
				;;
		esac
		;;
	* )
		ARCH=$(arch)
		ID=$(uname -s)
		VERSION_ID=$(uname -r)
		;;
esac

if test -z "$ARCH"
then
	RUNTIME="$ID.$VERSION_ID"
else
	RUNTIME="$ID.$VERSION_ID-$ARCH"
fi

RUNTIME="runtimes/$RUNTIME/native"

mkdir -p "pkg/$RUNTIME"

mv "$DLLPATH" "pkg/$RUNTIME/"

(
	set -e

	cd pkg

	zip "../$DLLNAME-$VERSION-$ID.$VERSION_ID.zip" "$RUNTIME/$DLLNAME.dll"
)
