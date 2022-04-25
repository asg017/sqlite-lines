## Goal

target file: `calendar.ndjson`,

- `185MB` total, `321,981` JSON objects
- count the number of strokes in the `"drawings"` property (`3,104,740`)

## Results

```
$ ./bench.sh
Benchmark #1: ./sqlite-lines.sh
  Time (mean ± σ):      1.099 s ±  0.006 s    [User: 1.058 s, System: 0.036 s]
  Range (min … max):    1.090 s …  1.111 s    10 runs

Benchmark #2: ./ndjson-cli.sh
  Time (mean ± σ):      2.878 s ±  0.056 s    [User: 2.841 s, System: 0.165 s]
  Range (min … max):    2.843 s …  3.034 s    10 runs

Benchmark #3: ./sqlite-utils.sh
  Time (mean ± σ):     19.497 s ±  0.698 s    [User: 19.490 s, System: 0.461 s]
  Range (min … max):   18.979 s … 21.323 s    10 runs

Summary
  './sqlite-lines.sh' ran
    2.62 ± 0.05 times faster than './ndjson-cli.sh'
   17.74 ± 0.64 times faster than './sqlite-utils.sh'
```
