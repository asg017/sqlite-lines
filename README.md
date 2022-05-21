# sqlite-lines

Query individual lines from blobs or files from SQLite.

`sqlite-lines` is a SQLite extension for reading lines from a file or blob.

```sql
.load ./lines0
select line from lines_read('logs.txt');
```

## Installing

`

### As a loadable extension

### From the browser with WASM/JavaScript

### The sqlite-lines CLI

## TODO

- [ ] handle `` etc. on rowid
- [ ] CLI fixes

## Benchmark

## Examples

- [ ] ndjson, geojsonl
- [ ] log files
- [ ] text files?
- [ ] using with fsdir
