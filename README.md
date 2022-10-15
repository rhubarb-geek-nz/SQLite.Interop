# SQLite.Interop Packaging

This project builds SQLite.Interop.dll as a platform specific binary.

The `package.sh` script will build from the versioned source for [System.Data.SQLite](https://system.data.sqlite.org). See script for URL and SHA256.

The `test.sh` script will use both `sqlite3` and `dotnet` to perform a test of the binary dll. `test.csproj` uses the [NuGet System.Data.SQLite.Core](https://www.nuget.org/packages/System.Data.SQLite.Core/) to compile. `test.sh` uses [Precompiled Binaries for the .NET Standard 2.0](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki) to execute.

These scripts are licensed using [GPLv3](http://www.gnu.org/licenses). [SQLite is public domain](https://www.sqlite.org/copyright.html).

See also [SQLite](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)
and [RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).
