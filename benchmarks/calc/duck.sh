#!/bin/bash
duckdb :memory: '.mode list' '.header off' \
  "select
    sum(json_array_length(column0, '$.drawing')) as num_strokes
  from read_csv_auto('../_data/calendar.ndjson', delim='|', header=False)"