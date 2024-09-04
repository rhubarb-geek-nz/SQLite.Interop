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

VERSION=1.0.118.0
SHA256=21093e5ffa803009c6b02e5f5495b5e07971fd0371c667359960419068a432f2

ZIPNAME="sqlite-netStandard20-binary-$VERSION.zip"

DOTNET=dotnet
DOTNET_CLI_TELEMETRY_OPTOUT=true
FRAMEWORK=net8.0
export DOTNET_CLI_TELEMETRY_OPTOUT

clean()
{
	rm -rf test.db */bin */obj tmp dotnet-sdk dotnet-install.sh
}

clean 

trap clean 0

unzip -l SQLite.Interop*.zip

sqlite3 test.db << EOF
CREATE TABLE MESSAGES (
	CONTENT VARCHAR(256)
);

INSERT INTO MESSAGES (CONTENT) VALUES ('Hello World');

SELECT * FROM MESSAGES;

EOF

if "$DOTNET" --version
then
	:
else
	curl --location --fail --silent --output dotnet-install.sh https://dot.net/v1/dotnet-install.sh

	chmod +x dotnet-install.sh

	./dotnet-install.sh --install-dir dotnet-sdk --channel $(echo "$FRAMEWORK" | sed s/net// )

	DOTNET="dotnet-sdk/dotnet"
fi

for d in */*.csproj
do
	"$DOTNET" build "$d" --configuration Release --framework "$FRAMEWORK"
done

RID=$("$DOTNET" "rid/bin/Release/$FRAMEWORK/rid.dll")

(
	set -e

	cd "test/bin/Release/$FRAMEWORK/"

	find runtimes -name SQLite.Interop.dll -type f
	rm -rf runtimes

	unzip ../../../../SQLite.Interop*.zip
	mv "runtimes/$RID/native/SQLite.Interop.dll" .
	rm -rf runtimes
)

(
	set -e

	mkdir tmp

	cd tmp

	curl --silent --fail --output "$ZIPNAME" --location "https://system.data.sqlite.org/blobs/$VERSION/$ZIPNAME"

	case $(uname) in
		Darwin )
			shasum -a 256 "$ZIPNAME" | grep "^$SHA256"
			;;
		* )
			sha256sum "$ZIPNAME" | grep "^$SHA256"
			;;
	esac

	unzip "$ZIPNAME" "*.dll"

	mv *.dll "../test/bin/Release/$FRAMEWORK"
)

rm -rf tmp

"$DOTNET" "test/bin/Release/$FRAMEWORK/test.dll"
