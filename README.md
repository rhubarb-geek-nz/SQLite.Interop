# SQLite.Interop Packaging

This project builds SQLite.Interop.dll as platform specific binary.

The `package.sh` script will build from the versioned source for [System.Data.SQLite](https://system.data.sqlite.org). See script for URL and SHA256.

The `test.sh` script will use both `sqlite3` and `dotnet` to perform a test of the binary dll. The `test.csproj` uses the [NuGet System.Data.SQLite.Core](https://www.nuget.org/packages/System.Data.SQLite.Core/) package.

These scripts are licensed using [GPLv3](http://www.gnu.org/licenses), [SQLite is public domain](https://www.sqlite.org/copyright.html).

See also [SQLite](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)
and [Runtimes](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).
