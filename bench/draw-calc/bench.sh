#!/bin/bash
hyperfine \
  './sqlite-lines.sh' \
  './ndjson-cli.sh' \
  './py.sh'
  #'./sqlite-utils.sh'
