#!/bin/bash
hyperfine \
  --warmup 2 \
  --export-json=results.json \
  --prepare 'rm sqlite-lines.db || true' './sqlite-lines.sh' \
  --prepare 'rm sqlite-utils.db || true' './sqlite-utils.sh'