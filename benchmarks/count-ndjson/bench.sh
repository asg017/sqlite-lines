#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
  './sqlite-lines.sh' \
  './sqlite-lines-cli.sh' \
  './unix.sh' \
  './duck.sh' \
  './py.sh' \
  './ndjson-cli.sh' \
  './dsq.sh' \
  './sqlite-utils.sh'
  './zq-json.sh' \
  './py-pandas.sh' \
  
