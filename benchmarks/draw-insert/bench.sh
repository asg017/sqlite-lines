#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
  --prepare 'rm sqlite-lines.db' './sqlite-lines.sh'\
  --prepare 'rm sqlite-utils.db' './sqlite-utils.sh'