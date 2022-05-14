#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
  './sqlite-lines.sh' \
  './sqlite-lines-cli.sh' \
  './ndjson-cli.sh' \
  './duck.sh' \
  './py.sh' \
  './py-pandas.sh' \
  './sqlite-utils.sh'
