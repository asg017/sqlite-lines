#!/bin/bash
duckdb :memory: '.mode list' '.header off' \
  "select
    count(*)
  from read_json_objects('../_data/calendar.ndjson')"
