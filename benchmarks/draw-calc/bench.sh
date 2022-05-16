#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
  './sqlite-lines.sh' \
  './sqlite-lines-cli.sh' \
  './ndjson-cli.sh' \
  './duck.sh' \
  './dsq.sh' \
  './sqlite-utils.sh'
  #'./zq-json.sh' \
  #'./py.sh' \
  #'./py-pandas.sh' \
  
