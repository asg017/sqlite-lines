#!/bin/bash
duckdb :memory: \
  "select
    sum(json_array_length(contents, '$.drawing')) as num_strokes
  from read_csv_auto('/Volumes/Sandisk1/draw/data/simplified/calendar.ndjson', delim='|', header=False)"
