# Benchmarks

Uses [hyperfine](https://github.com/sharkdp/hyperfine) for somewhat stable benchmarks.

Benchmarks results shown here were ran on an Ubuntu DigitalOcean droplet with 8GB of RAM.

The following version of the various tools benchmarks are here (ran with [`./versions.sh`](./versions.sh)):

```bash
+ ndjson-map --version
0.3.1
+ python3 --version
Python 3.8.10
+ duckdb --version
v0.3.4 662041e2b
+ dsq --version
dsq 0.17.0
+ sqlite3 :memory: '.load ../dist/lines0' 'select lines_version()'
v0.0.0
+ python3 -c 'import pandas as pd; print(pd.__version__)'
1.4.2
+ zq --version
Version: v1.0.0
```

## "Large" NDJSON Parsing

![](./draw-calc.png)

## text manipilation

![](./plain-filter.png)
