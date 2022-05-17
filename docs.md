# `sqlite-lines` Documentation

## Using in Projects

### As a Loadable Extension

`sqlite-lines` can be used as a [run-time loadable extension](https://www.sqlite.org/loadext.html). Depending on your machine's operating system, you can download either the `.dylib` (MacOS) or `.so` (Linux) shared library files (from either the TODO or [building yourself](#building-yourself)) and dynmically load it in your codebase.

For example, if you are using the [SQLite CLI](https://www.sqlite.org/cli.html), you can load the library like so:

```sql
.load ./lines0
select lines_version();
-- v0.0.-1
```

Or in Python, using the builtin [sqlite3 module](https://docs.python.org/3/library/sqlite3.html):

```python
import sqlite3
con = sqlite3.connect(":memory:")
con.enable_load_extension(True)
con.load_extension("./lines0")
print(con.execute("select lines_version()").fetchone())
# ('v0.0.-1',)
```

Or in Node.js using [better-sqlite3](https://github.com/WiseLibs/better-sqlite3):

```javascript
const Database = require("better-sqlite3");
const db = new Database(":memory:");
db.loadExtension("./lines0");
console.log(db.prepare("select lines_version()").get());
// { 'lines_version()': 'v0.0.-1' }
```

The default build will load all scalar and table functions available and documented under [API Reference](#api-reference).

The `0` in the filename (`lines0.dylib` or `lines.so`) denotes the major version of `sqlite-lines`. Currently `sqlite-lines` is pre v1, so expect breaking changes in future versions.

### Building Yourself

If you want to statically link `sqlite-lines` utilities into your own SQLite application, or if you want to build `sqlite-lines` for a different architecture

#### Compile-time options

##### `SQLITE_LINES_DISABLE_FILESYSTEM`

## The `sqlite-lines` CLI

https://github.com/mbostock/ndjson-cli

```
make cli
make test-cli
```

`dist/sqlite-lines`

## The `sqlite-lines` SQL.JS/WASM distribution

`sqlite-lines` uses a modified version of [sql.js](https://github.com/sql-js/sql.js) to offer a browser WASM/JavaScript interface to try out `sqlite-lines`. This is mostly for demonstration purposes and shouldn't be relied on too heavily.

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
```

### Table Functions

#### `lines(document, [delimeter])`

A table function that reads in the given _document_ (a TEXT or BLOB value) into memory, and generates a single row for every "line" in the document.

The generated rows have two usable columns - the first is `contents`, which is a text value of the split "line" that was found. The second, `rowid`, is the line number of the line in the document, starting at 1.

The default delimiter is the newline character `\n`. However, `sqlite-lines` will also strip away the carriage return character `\r` if it appears at the end of a line. You can specifier a different delimiter as the second parameter to `lines()`, but it must only be a single character.

Since `lines()` requires reading the full document into memory, the [`lines_read`](#linesreadpath-delimeter) table function is prefered whenever possible.

```sql
create table lines(
  line text,
  document blob hidden,
  delimeter char hidden
);
```

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

A table function

The schema of lines_read:

```sql
create table lines_read(
  line text,
  path text hidden,
  delimeter char hidden
);
```

Note that there also is a

```sql
select * from lines_read();
```
