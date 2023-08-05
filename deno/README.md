<!--- Generated with the deno_generate_package.sh script, don't edit by hand! -->

# `x/sqlite_lines` Deno Module

[![Tags](https://img.shields.io/github/release/asg017/sqlite-lines)](https://github.com/asg017/sqlite-lines/releases)
[![Doc](https://doc.deno.land/badge.svg)](https://doc.deno.land/https/deno.land/x/sqlite-lines@0.2.1/mod.ts)

The [`sqlite-lines`](https://github.com/asg017/sqlite-lines) SQLite extension is available to Deno developers with the [`x/sqlite_lines`](https://deno.land/x/sqlite-lines) Deno module. It works with [`x/sqlite3`](https://deno.land/x/sqlite3), the fastest and native Deno SQLite3 module.

```js
import { Database } from "https://deno.land/x/sqlite3@0.8.0/mod.ts";
import * as sqlite_lines from "https://deno.land/x/sqlite_lines@v0.2.1/mod.ts";

const db = new Database(":memory:");

  db.enableLoadExtension = true;
  db.loadExtension(sqlite_lines.getLoadablePath());

  const [version] = db
    .prepare("select lines_version()")
    .value<[string]>()!;

  console.log(version);

```

Like `x/sqlite3`, `x/sqlite_lines` requires network and filesystem permissions to download and cache the pre-compiled SQLite extension for your machine. Though `x/sqlite3` already requires `--allow-ffi` and `--unstable`, so you might as well use `--allow-all`/`-A`.

```bash
deno run -A --unstable <file>
```

`x/sqlite_lines` does not work with [`x/sqlite`](https://deno.land/x/sqlite@v3.7.0), which is a WASM-based Deno SQLite module that does not support loading extensions.
