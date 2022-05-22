#!/bin/bash
set -xeuo pipefail

ndjson-map --version
python3 --version
duckdb --version
dsq --version
sqlite3 :memory: '.load ../dist/lines0' 'select lines_version()'
python3 -c 'import pandas as pd; print(pd.__version__)'
zq --version
