# sqlite-lines

Query individual lines from blobs or files from SQLite.

## Installing

### As a loadable extension

### From the browser with WASM/JavaScript

### The sqlite-lines CLI

```
seq 1 1000000 > test_files/big.txt

dd if=/dev/zero of=test_files/big-line-line.txt bs=1000000 count=1001
```

## TODO

- [ ] memory leaks
  - [ ] close line after getdelim?
  - [ ] pCur->in should be freed?
- [ ] brazil geojson.nl example
- [ ] handle `SQLITE_INDEX_CONSTRAINT_GT` etc. on rowid
- [ ] CLI fixes

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
