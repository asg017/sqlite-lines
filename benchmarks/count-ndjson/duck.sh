#!/bin/bash
duckdb :memory: '.mode list' '.header off' \
  "select
    count(*)
  from read_csv_auto('../_data/calendar.ndjson', delim='|', header=False)"
