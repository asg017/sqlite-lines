#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
 './sqlite-lines.sh' \
 './sqlite-lines-cli.sh' \
 './unix.sh'