# sqlite-lines

```
seq 1 1000000 > test_files/big.txt

dd if=/dev/zero of=test_files/big-line-line.txt bs=1000000 count=1001
```

## TODO

- [ ] `sqlite3_limit` check on large lines
- [ ] check that delim is 1 char long
- [ ] handle `SQLITE_INDEX_CONSTRAINT_GT` etc. on rowid
- [ ] document/fix CRLF handling
- [ ] compile option for no filesystem access
- [ ] maybe `lines_stdin` table?
- [ ] more benchmarks
- [ ] parse log examples
- [ ] what CLI do

### Maybe future

- [ ] Proper glob support
- [ ] gzipped files
- [ ] S3 access?
- [ ] network access?

## Examples

- [ ] quickdraw, ndjson
- [ ] https://github.com/microsoft/USBuildingFootprints , https://github.com/microsoft/IdMyPhBuildingFootprints
- [ ] shp2json ? https://github.com/mbostock/ndjson-cli
- [ ] logs? pino logger?

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
