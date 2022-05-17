# sqlite-lines

Query individual lines from blobs or files from SQLite.

```
lines0.dylib
lines0.so
lines0-darwin-sqlite-lines
lines0-linux-amd64-sqlite-lines
lines0-darwin-sqlite3
lines0-linux-amd64-sqlite3
lines0-darwin-amd64.zip
lines0-linux-amd64.zip
lines0-sqljs.js
lines0-sqljs.wasm
```

## Installing

### As a loadable extension

### From the browser with WASM/JavaScript

### The sqlite-lines CLI

```
seq 1 1000000 > test_files/big.txt

dd if=/dev/zero of=test_files/big-line-line.txt bs=1000000 count=1001
```

## TODO

- [ ] rowid start at 1
- [ ] brazil geojson.nl example
- [ ] count ndjson
- [ ] `sqlite3_limit` check on large lines
- [ ] check that delim is 1 char long
- [ ] handle `SQLITE_INDEX_CONSTRAINT_GT` etc. on rowid
- [ ] document/fix CRLF handling
- [ ] compile option for no filesystem access
- [ ] maybe `lines_stdin` table?
- [ ] more benchmarks
- [ ] parse log examples
- [ ] what CLI do

## Benchmark

- [ ] ndjson
  - bigger data for insert/calc - microsoft buildings?
- [ ] plaintext, bench against cat/grep
- [ ] add test.sh to others
- [ ] output results as JSON, make fancy viz for main README
- [ ] any logs that can be filtered?

## Examples

- [ ] ndjson, geojsonl
- [ ] log files
- [ ] text files?
- [ ] using with fsdir
