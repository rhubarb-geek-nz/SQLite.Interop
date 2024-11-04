#!/bin/sh -e
#
#  Copyright 2023, Roger Brown
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

VERSION=1.0.119.0
SHA256=258bd0a766fc9dc678398ca366868354b2bbe22bda90a4bd2fd505489d1a5d83

ZIPNAME="sqlite-netFx-source-$VERSION.zip"

DOTNET=dotnet
DOTNET_CLI_TELEMETRY_OPTOUT=true
export DOTNET_CLI_TELEMETRY_OPTOUT
FRAMEWORK=net8.0

cleanup()
{
	rm -rf src pkg "$ZIPNAME" rid/bin rid/obj dotnet-sdk dotnet-install.sh
}

trap cleanup 0

rm -rf *.zip

cleanup

if "$DOTNET" --version
then
	:
else
	curl --location --fail --silent --output dotnet-install.sh https://dot.net/v1/dotnet-install.sh

	chmod +x dotnet-install.sh

	./dotnet-install.sh --install-dir dotnet-sdk --channel $(echo "$FRAMEWORK" | sed s/net// )

	DOTNET="dotnet-sdk/dotnet"
fi

"$DOTNET" build rid/rid.csproj --configuration Release --framework "$FRAMEWORK"

RID=$("$DOTNET" "rid/bin/Release/$FRAMEWORK/rid.dll")
RIDOS=$(
	echo $RID | sed y/-/\ / | while read A
	do
		RIDBASE=
		RIDLAST=

		for D in $A
		do
			if test -n "$RIDLAST"
			then
				if test -z "$RIDBASE"
				then
					RIDBASE="$RIDLAST"
				else
					RIDBASE="$RIDBASE-$RIDLAST"
				fi
			fi

			RIDLAST=$D
		done

		echo $RIDBASE
	done
)

echo RID=$RID
echo RIDOS=$RIDOS

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
	bash ./compile-interop-assembly-release.sh
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
		while read SRC DEST
		do
			DLL="pkg/runtimes/$RIDOS-$DEST/native/$DLLNAME.dll"
			mkdir -p $(dirname $DLL)
			lipo "$DLLPATH" -extract $SRC -output "$DLL"
			codesign --timestamp --sign "Developer ID Application: $APPLE_DEVELOPER" "$DLL"
		done <<EOF
arm64 arm64
x86_64 x64
EOF
		mkdir -p "pkg/runtimes/$RIDOS/native"
		lipo "pkg/runtimes/$RIDOS-"*"/native/$DLLNAME.dll" -create -output "pkg/runtimes/$RIDOS/native/$DLLNAME.dll"
		;;
	* )
		RUNTIME="runtimes/$RID/native"
		mkdir -p "pkg/$RUNTIME"
		mv "$DLLPATH" "pkg/$RUNTIME/"
		;;
esac

(
	set -e

	cd pkg

	find runtimes -type f | xargs chmod -x

	zip "../$DLLNAME-$VERSION-$RIDOS.zip" $(find runtimes -type f -name "$DLLNAME.dll")
)
