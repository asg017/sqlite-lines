#!/bin/bash
set -xeuo pipefail

ndjson-map --version
python3 --version
duckdb.0.3.3 --version
dsq --version
sqlite3x :memory: '.load ../dist/lines0' 'select lines_version()'
python3 -c 'import pandas as pd; print(pd.__version__)'
zq --version