## Goal

target file: `calendar.ndjson`

- `185MB` total, `321,981` JSON objects
- create a table with all objects with the schema `CREATE TABLE drawings(word, countrycode, timestamp, recognized, key_id, drawing);`

## Results

```
Benchmark #1: ./sqlite-lines.sh
  Time (mean ± σ):      3.281 s ±  0.186 s    [User: 2.387 s, System: 0.642 s]
  Range (min … max):    3.068 s …  3.577 s    10 runs

Benchmark #2: ./sqlite-utils.sh
  Time (mean ± σ):     26.239 s ±  1.207 s    [User: 21.284 s, System: 3.410 s]
  Range (min … max):   24.496 s … 28.472 s    10 runs

Summary
  './sqlite-lines.sh' ran
    8.00 ± 0.58 times faster than './sqlite-utils.sh'
```
