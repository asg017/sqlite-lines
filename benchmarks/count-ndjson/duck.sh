#!/bin/bash
duckdb.0.3.3 :memory: '.mode list' '.header off' \
  "select
    count(*)
  from read_csv_auto('../_data/calendar.ndjson', delim='|', header=False)"
