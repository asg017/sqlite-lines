# `sqlite-lines` Documentation

## Using in Projects

### As a Loadable Extension

`sqlite-lines` can be used as a [run-time loadable extension](https://www.sqlite.org/loadext.html). Depending on your machine's operating system, you can download either the `.dylib` (MacOS) or `.so` (Linux) shared library files (from either the TODO or [building yourself](#building-yourself)) and dynamically load it in your codebase.

The default build will load all scalar and table functions available and documented under [API Reference](#api-reference).

### Building Yourself

If you want to statically link `sqlite-lines` utilities into your own SQLite application, or if you want to build `sqlite-lines` for a different architecture, you'll need to build it yourself.

Building anything will require a `gcc` compiler and a MacOS/Linux machine (Windows not supported).

```
git clone git@github.com:asg017/sqlite-lines.git
cd sqlite-lines
```

#### Building a loadable extension

```
make loadable
```

This will create a `dist/html0.dylib` (MacOS) or `dist/html0.so` (Linux)[runtime-loadable extension[(https://www.sqlite.org/loadext.html).

To test, which requires `python3`:

```
make test-loadable
```

#### Building the SQLite CLI with `sqlite-lines` included

```
make sqlite3
make test-sqlite3
```

#### Building the `sqlite-lines` CLI

```
make cli
make test-cli
```

#### Building the WASM sql.js with `sqlite-lines` included

Requires [emscripten](https://github.com/emscripten-core/emscripten).

```
make sqljs

# will start a local server and open tests/test-sqljs.html for manual testing
make test-sqljs
```

#### Building into your own application

You have a few options. You only really need the `sqlite-lines.h` and `sqlite-lines.c`, so you could copy+paste those files into your own C/C++ application and bundle like that.

Additionally, you can run `make dist/lines0.o` to create an object file, and use that to link to your application.

If you want to load `sqlite-lines` functions/tables into a SQLite connection by default, look into the [`sqlite3_auto_extension()`](https://www.sqlite.org/c3ref/auto_extension.html) API and the `SQLITE_EXTRA_INIT` SQLite compile-time option (this project's Makefile has a few examples).

#### Compile-time options

**`SQLITE_LINES_DISABLE_FILESYSTEM`** an option that removes the `lines_read()` table function from the compiled output. This is the sole `sqlite-lines` function that touches the file system (because `lines()` only deals with in-memory data), which can be a security issue if you're running SQL queries from untrusted sources, like with Datasette.

**`SQLITE_LINES_ENTRYPOINT`** - optionally change the entrypoint name from `sqlite3_lines_init` to something else. This is used in the loadable "no filesystem" version of `sqlite-lines`, which uses `sqlite3_linesnofs_init` instead (because the compiled extension name is `lines_nofs0`).

## API Reference

### Scalar Functions

#### `lines_version()`

Returns the version string of the version of `sqlite-lines` the database connection is using. `sqlite-lines` uses [Semantic Versioning](https://semver.org/).

```sql
> select lines_version();
v0.0.0
```

#### `lines_debug()`

Returns a string with debugging information for `sqlite-lines`, including the version of `sqlite-line`, the commit hash of the main `sqlite-lines` repo that the build was made on, and the date it was built.

```sql
> select lines_debug();
Version: v0.0.0
Date: 2022-05-15T16:57:23Z-0700
Commit: c87a67c6e76
NO FILESYSTEM
```

The last `"NO FILESYSTEM"` line is only present in builds that use [`SQLITE_LINES_DISABLE_FILESYSTEM`](#SQLITE_LINES_DISABLE_FILESYSTEM) that removes the `lines_read()` function.

### Table Functions

#### `lines(document, [delimeter])`

```sql
create table lines(
  line text,
  document blob hidden, -- 1st input parameter: text or blob of document to read
  delimeter char hidden -- 2nd input parameter: option 1-character to split on
);
```

A table function that reads in the given _document_ (a TEXT or BLOB value) into memory, and generates a single row for every "line" in the document.

The generated rows have two usable columns - the first is `line`, which is a text value of the split "line" that was found. The second, `rowid`, is the line number of the line in the document, starting at 1.

The default delimiter is the newline character `\n`. However, `sqlite-lines` will also strip away the carriage return character `\r` if it appears at the end of a line, to support CRLF files. You can specifier a different delimiter as the second parameter to `lines()`, but it must only be a single character.

Since `lines()` requires reading the full document into memory, the [`lines_read`](#linesreadpath-delimeter) table function is prefered whenever possible.

```sql
select rowid, line from lines('a
b
c');
/*
rowid|line
1|a
2|b
3|c
*/

```

#### `lines_read(path, [delimeter])`

```sql
create table lines_read(
  line text,
  path text hidden,     -- 1st input parameter: text or blob of document to read
  delimeter char hidden -- 2nd input parameter: option 1-character to split on
);
```

A table function that reads the file at the given _path_, and generates a single row for every "line" in that file.

The API and generated rows are the same as the `lines()` function - except this function will read from the filesystem, by-passing SQLite's [1GB limit](https://www.sqlite.org/limits.html#max_length).

```sql
select * from lines_read("my-file.txt");

select
  line -> '$.id'   as id,
  line -> '$.name' as name
from lines_read("my-file.ndjson");
```
