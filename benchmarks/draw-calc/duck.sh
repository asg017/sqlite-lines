#!/bin/bash
duckdb.0.3.3 :memory: \
  "select
    sum(json_array_length(column0, '$.drawing')) as num_strokes
  from read_csv_auto('/Volumes/Sandisk1/draw/data/simplified/calendar.ndjson', delim='|', header=False)"
