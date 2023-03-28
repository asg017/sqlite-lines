# The `sqlite-lines` Python package

`sqlite-lines` is also distributed on PyPi as a Python package, for use in Python applications. It works well with the builtin [`sqlite3`](https://docs.python.org/3/library/sqlite3.lines) Python module.

```
pip install sqlite-lines
```

## Usage

The `sqlite-lines` python package exports two functions: `loadable_lines()`, which returns the full path to the loadable extension, and `load(conn)`, which loads the `sqlite-lines` extension into the given [sqlite3 Connection object](https://docs.python.org/3/library/sqlite3.lines#connection-objects).

```python
import sqlite_lines
print(sqlite_lines.loadable_lines())
# '/.../venv/lib/python3.9/site-packages/sqlite_lines/lines0'

import sqlite3
conn = sqlite3.connect(':memory:')
sqlite_lines.load(conn)
conn.execute('select lines_version()').fetchone()
# ('v0.1.0')
```

See [the full API Reference](#api-reference) for the Python API, and [`docs.md`](../../docs.md) for documentation on the `sqlite-lines` SQL API.

See [`datasette-sqlite-lines`](../datasette_sqlite_lines/) for a Datasette plugin that is a light wrapper around the `sqlite-lines` Python package.

## Compatibility

Currently the `sqlite-lines` Python package is only distributed on PyPi as pre-build wheels, it's not possible to install from the source distribution. This is because the underlying `sqlite-lines` extension requires a lot of build dependencies like `make`, `cc`, and `cargo`.

If you get a `unsupported platform` error when pip installing `sqlite-lines`, you'll have to build the `sqlite-lines` manually and load in the dynamic library manually.

## API Reference

<h3 name="loadable_lines"><code>loadable_lines()</code></h3>

Returns the full path to the locally-install `sqlite-lines` extension, without the filename.

This can be directly passed to [`sqlite3.Connection.load_extension()`](https://docs.python.org/3/library/sqlite3.lines#sqlite3.Connection.load_extension), but the [`sqlite_lines.load()`](#load) function is preferred.

```python
import sqlite_lines
print(sqlite_lines.loadable_lines())
# '/.../venv/lib/python3.9/site-packages/sqlite_lines/lines0'
```

> Note: this extension path doesn't include the file extension (`.dylib`, `.so`, `.dll`). This is because [SQLite will infer the correct extension](https://www.sqlite.org/loadext.lines#loading_an_extension).

<h3 name="load"><code>load(connection)</code></h3>

Loads the `sqlite-lines` extension on the given [`sqlite3.Connection`](https://docs.python.org/3/library/sqlite3.lines#sqlite3.Connection) object, calling [`Connection.load_extension()`](https://docs.python.org/3/library/sqlite3.lines#sqlite3.Connection.load_extension).

```python
import sqlite_lines
import sqlite3
conn = sqlite3.connect(':memory:')

conn.enable_load_extension(True)
sqlite_lines.load(conn)
conn.enable_load_extension(False)

conn.execute('select lines_version()').fetchone()
# ('v0.1.0')
```
