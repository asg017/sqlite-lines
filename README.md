## TODO

- [ ] Proper glob support
- [ ] gzipped files
- [ ] S3 access?
- [ ] network access?
- [ ] special delim
- [ ] rename to `cat`, `head`, `tail` ?
- [ ] CLI?
  - `cat a.log | lines out.db 'select * from stdin where contents -> "type" == "Polygon"'`

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
