# `sqlite-lines` Documentation

## Using in Projects

### As a Loadable Extension

`sqlite-lines` can be used as a [run-time loadable extension](https://www.sqlite.org/loadext.html). Depending on your machine's operating system, you can download either the `.dylib` (MacOS) or `.so` (Linux) shared library files (from either the TODO or [building yourself](#building-yourself)) and dynmically load it in your codebase.

The default build will load all scalar and table functions available and documented under [API Reference](#api-reference).

### Building Yourself

If you want to statically link `sqlite-lines` utilities into your own SQLite application, or if you want to build `sqlite-lines` for a different architecture, you'll need to build it yourself.

#### Compile-time options

##### `SQLITE_LINES_DISABLE_FILESYSTEM`

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
